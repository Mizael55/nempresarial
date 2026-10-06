-- ============================================================================
-- SALES & POS MODULE - STORED PROCEDURES & VIEWS
-- ============================================================================

-- 1. View: v_sales_summary
CREATE OR REPLACE VIEW v_sales_summary AS
SELECT 
    s.id,
    s.invoice_number,
    s.branch_id,
    b.name AS branch_name,
    s.customer_id,
    COALESCE(c.name, 'Consumidor Final') AS customer_name,
    c.tax_id AS customer_tax_id,
    s.status,
    s.subtotal,
    s.discount_amount,
    s.tax_amount,
    s.total_amount,
    s.cost_amount,
    s.payment_method,
    s.payment_status,
    s.notes,
    s.created_by,
    COALESCE(p.full_name, 'Sistema') AS cashier_name,
    s.created_at,
    (SELECT COUNT(*) FROM sale_items si WHERE si.sale_id = s.id) AS items_count
FROM sales s
LEFT JOIN branches b ON b.id = s.branch_id
LEFT JOIN customers c ON c.id = s.customer_id
LEFT JOIN profiles p ON p.id = s.created_by;

-- Grant permissions on the view
GRANT SELECT ON v_sales_summary TO anon, authenticated, postgres;

-- 2. Function: process_sale
CREATE OR REPLACE FUNCTION process_sale(
    p_branch_id UUID DEFAULT NULL,
    p_customer_id UUID DEFAULT NULL,
    p_items JSONB DEFAULT '[]'::jsonb,
    p_payment_method TEXT DEFAULT 'cash',
    p_payment_status TEXT DEFAULT 'paid',
    p_discount_total NUMERIC DEFAULT 0.00,
    p_notes TEXT DEFAULT NULL,
    p_created_by UUID DEFAULT NULL,
    p_payments JSONB DEFAULT '[]'::jsonb
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_branch_id UUID;
    v_sale_id UUID;
    v_invoice_number VARCHAR(50);
    v_count INT;
    v_item JSONB;
    v_product_id UUID;
    v_product_name VARCHAR(200);
    v_product_cost NUMERIC;
    v_quantity NUMERIC;
    v_unit_price NUMERIC;
    v_item_discount NUMERIC;
    v_item_tax NUMERIC;
    v_item_total NUMERIC;
    v_total_subtotal NUMERIC := 0.00;
    v_total_tax NUMERIC := 0.00;
    v_total_amount NUMERIC := 0.00;
    v_total_cost NUMERIC := 0.00;
    v_payment JSONB;
    v_current_stock NUMERIC;
    v_new_stock NUMERIC;
BEGIN
    -- Determinar branch_id
    IF p_branch_id IS NULL THEN
        SELECT id INTO v_branch_id FROM branches WHERE is_main = true LIMIT 1;
        IF v_branch_id IS NULL THEN
            SELECT id INTO v_branch_id FROM branches LIMIT 1;
        END IF;
    ELSE
        v_branch_id := p_branch_id;
    END IF;

    IF v_branch_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'No se encontró una sucursal activa.');
    END IF;

    -- Validar que haya items
    IF jsonb_array_length(p_items) = 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'La venta debe contener al menos un producto.');
    END IF;

    -- Generar correlativo de factura único (FAC-000001)
    SELECT COUNT(*) + 1 INTO v_count FROM sales;
    v_invoice_number := 'FAC-' || LPAD(v_count::text, 6, '0');
    WHILE EXISTS (SELECT 1 FROM sales WHERE invoice_number = v_invoice_number) LOOP
        v_count := v_count + 1;
        v_invoice_number := 'FAC-' || LPAD(v_count::text, 6, '0');
    END LOOP;

    -- Calcular totales preliminares
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_quantity := COALESCE((v_item->>'quantity')::numeric, 1.0);
        v_unit_price := COALESCE((v_item->>'unit_price')::numeric, 0.0);
        v_item_discount := COALESCE((v_item->>'discount_amount')::numeric, 0.0);
        v_item_tax := COALESCE((v_item->>'tax_amount')::numeric, 0.0);
        v_item_total := (v_quantity * v_unit_price) - v_item_discount + v_item_tax;

        v_product_id := (v_item->>'product_id')::uuid;
        SELECT name, cost_price INTO v_product_name, v_product_cost FROM products WHERE id = v_product_id;
        IF v_product_cost IS NULL THEN v_product_cost := 0.00; END IF;

        v_total_subtotal := v_total_subtotal + (v_quantity * v_unit_price) - v_item_discount;
        v_total_tax := v_total_tax + v_item_tax;
        v_total_amount := v_total_amount + v_item_total;
        v_total_cost := v_total_cost + (v_quantity * v_product_cost);
    END LOOP;

    -- Aplicar descuento global si existe
    IF p_discount_total > 0 THEN
        v_total_amount := GREATEST(0.00, v_total_amount - p_discount_total);
    END IF;

    -- 1. Insertar la venta
    INSERT INTO sales (
        invoice_number,
        branch_id,
        customer_id,
        status,
        subtotal,
        discount_amount,
        tax_amount,
        total_amount,
        cost_amount,
        payment_method,
        payment_status,
        notes,
        created_by
    ) VALUES (
        v_invoice_number,
        v_branch_id,
        p_customer_id,
        'completed',
        v_total_subtotal,
        p_discount_total,
        v_total_tax,
        v_total_amount,
        v_total_cost,
        p_payment_method::payment_method_type,
        p_payment_status::payment_status_type,
        p_notes,
        p_created_by
    ) RETURNING id INTO v_sale_id;

    -- 2. Insertar items y rebajar stock
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_id := (v_item->>'product_id')::uuid;
        v_quantity := COALESCE((v_item->>'quantity')::numeric, 1.0);
        v_unit_price := COALESCE((v_item->>'unit_price')::numeric, 0.0);
        v_item_discount := COALESCE((v_item->>'discount_amount')::numeric, 0.0);
        v_item_tax := COALESCE((v_item->>'tax_amount')::numeric, 0.0);
        v_item_total := (v_quantity * v_unit_price) - v_item_discount + v_item_tax;

        SELECT name, cost_price INTO v_product_name, v_product_cost FROM products WHERE id = v_product_id;
        IF v_product_cost IS NULL THEN v_product_cost := 0.00; END IF;

        INSERT INTO sale_items (
            sale_id,
            product_id,
            product_name,
            quantity,
            unit_cost,
            unit_price,
            discount_amount,
            tax_amount,
            total_amount
        ) VALUES (
            v_sale_id,
            v_product_id,
            v_product_name,
            v_quantity,
            v_product_cost,
            v_unit_price,
            v_item_discount,
            v_item_tax,
            v_item_total
        );

        -- Rebajar inventario de forma segura
        SELECT current_stock INTO v_current_stock 
        FROM inventory 
        WHERE product_id = v_product_id AND branch_id = v_branch_id;

        IF NOT FOUND THEN
            -- Si no existía registro de inventario, crearlo en 0 - cantidad
            v_current_stock := 0.00;
            v_new_stock := -v_quantity;
            INSERT INTO inventory (product_id, branch_id, current_stock, reserved_stock)
            VALUES (v_product_id, v_branch_id, v_new_stock, 0.00);
        ELSE
            v_new_stock := v_current_stock - v_quantity;
            UPDATE inventory 
            SET current_stock = v_new_stock, updated_at = NOW()
            WHERE product_id = v_product_id AND branch_id = v_branch_id;
        END IF;

        -- Registrar movimiento en kardex de inventario
        INSERT INTO inventory_movements (
            product_id,
            branch_id,
            movement_type,
            quantity,
            previous_stock,
            new_stock,
            unit_cost,
            reference_id,
            notes,
            created_by
        ) VALUES (
            v_product_id,
            v_branch_id,
            'sale',
            v_quantity,
            v_current_stock,
            v_new_stock,
            v_product_cost,
            v_sale_id,
            'Venta Factura #' || v_invoice_number,
            p_created_by
        );
    END LOOP;

    -- 3. Registrar pagos
    IF jsonb_array_length(p_payments) > 0 THEN
        FOR v_payment IN SELECT * FROM jsonb_array_elements(p_payments)
        LOOP
            INSERT INTO sale_payments (
                sale_id,
                payment_method,
                amount,
                reference
            ) VALUES (
                v_sale_id,
                COALESCE(v_payment->>'payment_method', 'cash')::payment_method_type,
                (v_payment->>'amount')::numeric,
                v_payment->>'reference'
            );
        END LOOP;
    ELSE
        INSERT INTO sale_payments (
            sale_id,
            payment_method,
            amount,
            reference
        ) VALUES (
            v_sale_id,
            p_payment_method::payment_method_type,
            v_total_amount,
            NULL
        );
    END IF;

    -- 4. Si fue a crédito y tiene cliente, sumar al balance pendiente del cliente
    IF p_payment_method = 'credit' AND p_customer_id IS NOT NULL THEN
        UPDATE customers 
        SET current_balance = COALESCE(current_balance, 0.00) + v_total_amount,
            updated_at = NOW()
        WHERE id = p_customer_id;
    END IF;

    -- 5. Audit log
    INSERT INTO audit_logs (
        user_id,
        action,
        entity,
        entity_id,
        details
    ) VALUES (
        p_created_by,
        'CREATE',
        'sale',
        v_sale_id,
        jsonb_build_object(
            'invoice_number', v_invoice_number,
            'total_amount', v_total_amount,
            'payment_method', p_payment_method
        )
    );

    RETURN jsonb_build_object(
        'success', true,
        'sale_id', v_sale_id,
        'invoice_number', v_invoice_number,
        'subtotal', v_total_subtotal,
        'tax_amount', v_total_tax,
        'total_amount', v_total_amount,
        'items_count', jsonb_array_length(p_items)
    );
END;
$$;

-- 3. Function: void_sale (Anulación atómica)
CREATE OR REPLACE FUNCTION void_sale(
    p_sale_id UUID,
    p_reason TEXT DEFAULT 'Anulación por usuario',
    p_user_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_sale RECORD;
    v_item RECORD;
    v_current_stock NUMERIC;
    v_new_stock NUMERIC;
BEGIN
    SELECT * INTO v_sale FROM sales WHERE id = p_sale_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Venta no encontrada.');
    END IF;

    IF v_sale.status = 'cancelled' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Esta venta ya se encuentra anulada.');
    END IF;

    -- 1. Marcar estado cancelled
    UPDATE sales 
    SET status = 'cancelled',
        notes = COALESCE(notes, '') || ' [ANULADA: ' || p_reason || ']',
        updated_at = NOW()
    WHERE id = p_sale_id;

    -- 2. Devolver stock de cada item al inventario
    FOR v_item IN SELECT * FROM sale_items WHERE sale_id = p_sale_id
    LOOP
        SELECT current_stock INTO v_current_stock 
        FROM inventory 
        WHERE product_id = v_item.product_id AND branch_id = v_sale.branch_id;

        IF FOUND THEN
            v_new_stock := v_current_stock + v_item.quantity;
            UPDATE inventory 
            SET current_stock = v_new_stock, updated_at = NOW()
            WHERE product_id = v_item.product_id AND branch_id = v_sale.branch_id;

            INSERT INTO inventory_movements (
                product_id,
                branch_id,
                movement_type,
                quantity,
                previous_stock,
                new_stock,
                unit_cost,
                reference_id,
                notes,
                created_by
            ) VALUES (
                v_item.product_id,
                v_sale.branch_id,
                'return',
                v_item.quantity,
                v_current_stock,
                v_new_stock,
                v_item.unit_cost,
                p_sale_id,
                'Anulación Factura #' || v_sale.invoice_number || ' - ' || p_reason,
                p_user_id
            );
        END IF;
    END LOOP;

    -- 3. Si fue a crédito, rebajar balance del cliente
    IF v_sale.payment_method = 'credit' AND v_sale.customer_id IS NOT NULL THEN
        UPDATE customers 
        SET current_balance = GREATEST(0.00, COALESCE(current_balance, 0.00) - v_sale.total_amount),
            updated_at = NOW()
        WHERE id = v_sale.customer_id;
    END IF;

    -- 4. Audit log
    INSERT INTO audit_logs (
        user_id,
        action,
        entity,
        entity_id,
        details
    ) VALUES (
        p_user_id,
        'VOID',
        'sale',
        p_sale_id,
        jsonb_build_object('reason', p_reason, 'invoice_number', v_sale.invoice_number)
    );

    RETURN jsonb_build_object(
        'success', true, 
        'message', 'Venta anulada y stock devuelto exitosamente.'
    );
END;
$$;

-- Grant execute permissions to anon and authenticated
GRANT EXECUTE ON FUNCTION process_sale TO anon, authenticated, postgres;
GRANT EXECUTE ON FUNCTION void_sale TO anon, authenticated, postgres;
