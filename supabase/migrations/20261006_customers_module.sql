-- ============================================================================
-- MIGRACIÓN FASE 8: MÓDULO DE CLIENTES & CUENTAS POR COBRAR (CXC)
-- Sistema Nubiko Empresarial
-- ============================================================================

-- 1. VISTA RESUMEN DE CLIENTES CON ESTADÍSTICAS
CREATE OR REPLACE VIEW v_customers_summary AS
SELECT 
    c.id,
    c.name,
    c.tax_id,
    c.email,
    c.phone,
    c.whatsapp,
    c.address,
    COALESCE(c.credit_limit, 0.00) AS credit_limit,
    COALESCE(c.current_balance, 0.00) AS current_balance,
    c.is_active,
    c.notes,
    c.created_at,
    c.updated_at,
    COUNT(s.id)::int AS total_sales_count,
    COALESCE(SUM(CASE WHEN s.status != 'cancelled' THEN s.total_amount ELSE 0.00 END), 0.00) AS total_purchased_amount,
    MAX(s.created_at) AS last_purchase_at
FROM customers c
LEFT JOIN sales s ON s.customer_id = c.id
GROUP BY c.id;

-- 2. FUNCIÓN ATÓMICA PARA REGISTRAR PAGO / ABONO DE CLIENTE (CXC)
CREATE OR REPLACE FUNCTION register_customer_payment(
    p_customer_id UUID,
    p_amount NUMERIC(15,2),
    p_payment_method TEXT,
    p_reference TEXT,
    p_notes TEXT,
    p_received_by UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_payment_id UUID;
    v_previous_balance NUMERIC(15,2);
    v_new_balance NUMERIC(15,2);
    v_customer_name VARCHAR(150);
    v_remaining_payment NUMERIC(15,2) := p_amount;
    v_sale RECORD;
BEGIN
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'El monto del abono debe ser mayor a 0.00';
    END IF;

    SELECT name, COALESCE(current_balance, 0.00)
    INTO v_customer_name, v_previous_balance
    FROM customers
    WHERE id = p_customer_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cliente no encontrado';
    END IF;

    -- 1. Insertar registro en customer_payments
    INSERT INTO customer_payments (
        customer_id,
        amount,
        payment_method,
        reference,
        notes,
        received_by,
        created_at
    ) VALUES (
        p_customer_id,
        p_amount,
        p_payment_method::payment_method_type,
        p_reference,
        p_notes,
        p_received_by,
        NOW()
    ) RETURNING id INTO v_payment_id;

    -- 2. Disminuir balance del cliente
    v_new_balance := GREATEST(0.00, v_previous_balance - p_amount);
    UPDATE customers
    SET current_balance = v_new_balance,
        updated_at = NOW()
    WHERE id = p_customer_id;

    -- 3. Marcar facturas a crédito pendientes como pagadas en orden cronológico
    FOR v_sale IN 
        SELECT id, total_amount, payment_status 
        FROM sales 
        WHERE customer_id = p_customer_id 
          AND payment_status = 'pending' 
          AND status != 'cancelled'
        ORDER BY created_at ASC
    LOOP
        IF v_remaining_payment >= v_sale.total_amount THEN
            UPDATE sales 
            SET payment_status = 'paid'::payment_status_type,
                updated_at = NOW()
            WHERE id = v_sale.id;

            v_remaining_payment := v_remaining_payment - v_sale.total_amount;
        ELSE
            -- El pago cubrió parcialmente o ya no queda monto
            EXIT;
        END IF;
    END LOOP;

    -- 4. Registrar en bitácora de auditoría
    INSERT INTO audit_logs (
        user_id,
        action,
        table_name,
        record_id,
        new_values
    ) VALUES (
        p_received_by,
        'INSERT',
        'customer_payments',
        v_payment_id,
        jsonb_build_object(
            'customer_id', p_customer_id,
            'customer_name', v_customer_name,
            'amount', p_amount,
            'previous_balance', v_previous_balance,
            'new_balance', v_new_balance,
            'payment_method', p_payment_method
        )
    );

    RETURN jsonb_build_object(
        'success', true,
        'payment_id', v_payment_id,
        'customer_name', v_customer_name,
        'amount', p_amount,
        'previous_balance', v_previous_balance,
        'new_balance', v_new_balance
    );
END;
$$;
