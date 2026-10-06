-- ============================================================================
-- MIGRACIÓN FASE 7: MÓDULO DE COMPRAS Y PROVEEDORES
-- Sistema Nubiko Empresarial
-- ============================================================================

-- 1. VISTA RESUMEN DE COMPRAS
CREATE OR REPLACE VIEW v_purchases_summary AS
SELECT 
    p.id,
    p.purchase_number,
    p.supplier_id,
    COALESCE(s.name, 'Proveedor No Registrado') AS supplier_name,
    s.tax_id AS supplier_tax_id,
    p.branch_id,
    COALESCE(b.name, 'Principal') AS branch_name,
    p.status::text AS status,
    p.subtotal,
    p.tax_amount,
    p.total_amount,
    p.payment_method::text AS payment_method,
    p.payment_status::text AS payment_status,
    p.notes,
    p.created_by,
    COALESCE(u.full_name, 'Sistema') AS purchaser_name,
    p.created_at,
    p.updated_at,
    COUNT(pi.id)::int AS items_count
FROM purchases p
LEFT JOIN suppliers s ON s.id = p.supplier_id
LEFT JOIN branches b ON b.id = p.branch_id
LEFT JOIN profiles u ON u.id = p.created_by
LEFT JOIN purchase_items pi ON pi.purchase_id = p.id
GROUP BY p.id, s.name, s.tax_id, b.name, u.full_name;

-- 2. FUNCIÓN ATÓMICA PARA PROCESAR COMPRA Y ENTRADA AL INVENTARIO
CREATE OR REPLACE FUNCTION process_purchase(
    p_supplier_id UUID,
    p_branch_id UUID,
    p_payment_method TEXT,
    p_payment_status TEXT,
    p_notes TEXT,
    p_custom_invoice_number VARCHAR(50),
    p_tax_amount NUMERIC(15,2),
    p_items JSONB,
    p_user_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_purchase_id UUID;
    v_purchase_number VARCHAR(50);
    v_next_num INT;
    v_subtotal NUMERIC(15,2) := 0.00;
    v_total_amount NUMERIC(15,2) := 0.00;
    v_item JSONB;
    v_product_id UUID;
    v_quantity NUMERIC(12,2);
    v_unit_cost NUMERIC(15,2);
    v_item_total NUMERIC(15,2);
    v_product_name VARCHAR(200);
    v_current_stock NUMERIC(12,2);
    v_new_stock NUMERIC(12,2);
    v_branch_id UUID := p_branch_id;
BEGIN
    -- Validar sucursal (usar principal por defecto si es nula)
    IF v_branch_id IS NULL THEN
        SELECT id INTO v_branch_id FROM branches WHERE is_main = true LIMIT 1;
        IF v_branch_id IS NULL THEN
            SELECT id INTO v_branch_id FROM branches LIMIT 1;
        END IF;
    END IF;

    -- Validar items
    IF jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'La compra debe contener al menos un producto';
    END IF;

    -- Calcular subtotal sumando todos los items
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_quantity := (v_item->>'quantity')::NUMERIC(12,2);
        v_unit_cost := (v_item->>'unit_cost')::NUMERIC(15,2);
        v_subtotal := v_subtotal + (v_quantity * v_unit_cost);
    END LOOP;

    v_total_amount := v_subtotal + COALESCE(p_tax_amount, 0.00);

    -- Determinar número de compra
    IF p_custom_invoice_number IS NOT NULL AND length(trim(p_custom_invoice_number)) > 0 THEN
        v_purchase_number := trim(p_custom_invoice_number);
    ELSE
        SELECT COALESCE(MAX(SUBSTRING(purchase_number FROM '[0-9]+')::INT), 0) + 1
        INTO v_next_num
        FROM purchases
        WHERE purchase_number ~ '^COM-[0-9]+';
        
        v_purchase_number := 'COM-' || LPAD(v_next_num::TEXT, 6, '0');
    END IF;

    -- Crear registro de Compra
    INSERT INTO purchases (
        purchase_number,
        supplier_id,
        branch_id,
        status,
        subtotal,
        tax_amount,
        total_amount,
        payment_method,
        payment_status,
        notes,
        created_by,
        created_at
    ) VALUES (
        v_purchase_number,
        p_supplier_id,
        v_branch_id,
        'received'::purchase_status_type,
        v_subtotal,
        COALESCE(p_tax_amount, 0.00),
        v_total_amount,
        p_payment_method::payment_method_type,
        p_payment_status::payment_status_type,
        p_notes,
        p_user_id,
        NOW()
    ) RETURNING id INTO v_purchase_id;

    -- Procesar cada item: guardar renglón, actualizar costo de producto, aumentar stock y registrar kardex
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_id := (v_item->>'product_id')::UUID;
        v_quantity := (v_item->>'quantity')::NUMERIC(12,2);
        v_unit_cost := (v_item->>'unit_cost')::NUMERIC(15,2);
        v_item_total := v_quantity * v_unit_cost;

        SELECT name INTO v_product_name FROM products WHERE id = v_product_id;
        IF v_product_name IS NULL THEN
            v_product_name := 'Producto ' || v_product_id;
        END IF;

        -- 1. Insertar detalle
        INSERT INTO purchase_items (
            purchase_id,
            product_id,
            product_name,
            quantity,
            unit_cost,
            total_amount
        ) VALUES (
            v_purchase_id,
            v_product_id,
            v_product_name,
            v_quantity,
            v_unit_cost,
            v_item_total
        );

        -- 2. Actualizar costo de reposición del producto
        UPDATE products 
        SET cost_price = v_unit_cost,
            updated_at = NOW()
        WHERE id = v_product_id;

        -- 3. Aumentar inventario en la sucursal (Upsert)
        INSERT INTO inventory (product_id, branch_id, quantity)
        VALUES (v_product_id, v_branch_id, v_quantity)
        ON CONFLICT (product_id, branch_id)
        DO UPDATE SET 
            quantity = inventory.quantity + EXCLUDED.quantity,
            updated_at = NOW()
        RETURNING quantity INTO v_new_stock;

        v_current_stock := v_new_stock - v_quantity;

        -- 4. Registrar movimiento de inventario (tipo 'purchase')
        INSERT INTO inventory_movements (
            product_id,
            branch_id,
            movement_type,
            quantity,
            previous_quantity,
            new_quantity,
            unit_cost,
            reference_type,
            reference_id,
            reason,
            created_by
        ) VALUES (
            v_product_id,
            v_branch_id,
            'purchase'::inventory_movement_type,
            v_quantity,
            v_current_stock,
            v_new_stock,
            v_unit_cost,
            'purchases',
            v_purchase_id,
            'Entrada por compra: ' || v_purchase_number,
            p_user_id
        );
    END LOOP;

    -- 5. Si la compra es a crédito / pendiente de pago, actualizar deuda con proveedor
    IF p_supplier_id IS NOT NULL AND p_payment_status IN ('pending', 'partial') THEN
        UPDATE suppliers
        SET current_debt = current_debt + v_total_amount,
            updated_at = NOW()
        WHERE id = p_supplier_id;
    END IF;

    -- 6. Auditoría
    INSERT INTO audit_logs (
        user_id,
        action,
        table_name,
        record_id,
        new_values
    ) VALUES (
        p_user_id,
        'INSERT',
        'purchases',
        v_purchase_id,
        jsonb_build_object(
            'purchase_number', v_purchase_number,
            'total_amount', v_total_amount,
            'items_count', jsonb_array_length(p_items)
        )
    );

    RETURN jsonb_build_object(
        'success', true,
        'purchase_id', v_purchase_id,
        'purchase_number', v_purchase_number,
        'total_amount', v_total_amount
    );
END;
$$;

-- 3. FUNCIÓN PARA ANULAR COMPRA (Reversión de Stock y Deuda)
CREATE OR REPLACE FUNCTION void_purchase(
    p_purchase_id UUID,
    p_reason TEXT,
    p_user_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_purchase RECORD;
    v_item RECORD;
    v_current_stock NUMERIC(12,2);
    v_new_stock NUMERIC(12,2);
BEGIN
    SELECT * INTO v_purchase FROM purchases WHERE id = p_purchase_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Compra no encontrada';
    END IF;

    IF v_purchase.status = 'cancelled' THEN
        RAISE EXCEPTION 'La compra ya se encuentra anulada';
    END IF;

    -- Revertir stock de cada item
    FOR v_item IN SELECT * FROM purchase_items WHERE purchase_id = p_purchase_id
    LOOP
        SELECT quantity INTO v_current_stock 
        FROM inventory 
        WHERE product_id = v_item.product_id AND branch_id = v_purchase.branch_id;

        IF v_current_stock IS NULL THEN
            v_current_stock := 0.00;
        END IF;

        v_new_stock := GREATEST(0.00, v_current_stock - v_item.quantity);

        UPDATE inventory 
        SET quantity = v_new_stock,
            updated_at = NOW()
        WHERE product_id = v_item.product_id AND branch_id = v_purchase.branch_id;

        -- Registrar movimiento de salida por anulación
        INSERT INTO inventory_movements (
            product_id,
            branch_id,
            movement_type,
            quantity,
            previous_quantity,
            new_quantity,
            unit_cost,
            reference_type,
            reference_id,
            reason,
            created_by
        ) VALUES (
            v_item.product_id,
            v_purchase.branch_id,
            'adjustment_out'::inventory_movement_type,
            -v_item.quantity,
            v_current_stock,
            v_new_stock,
            v_item.unit_cost,
            'purchases',
            p_purchase_id,
            'Anulación de compra ' || v_purchase.purchase_number || ': ' || COALESCE(p_reason, 'Sin motivo'),
            p_user_id
        );
    END LOOP;

    -- Ajustar deuda con proveedor si estaba a crédito
    IF v_purchase.supplier_id IS NOT NULL AND v_purchase.payment_status IN ('pending', 'partial') THEN
        UPDATE suppliers
        SET current_debt = GREATEST(0.00, current_debt - v_purchase.total_amount),
            updated_at = NOW()
        WHERE id = v_purchase.supplier_id;
    END IF;

    -- Marcar compra como cancelada
    UPDATE purchases
    SET status = 'cancelled'::purchase_status_type,
        notes = COALESCE(notes, '') || ' [ANULADA: ' || COALESCE(p_reason, '') || ']',
        updated_at = NOW()
    WHERE id = p_purchase_id;

    -- Auditoría
    INSERT INTO audit_logs (
        user_id,
        action,
        table_name,
        record_id,
        new_values
    ) VALUES (
        p_user_id,
        'VOID',
        'purchases',
        p_purchase_id,
        jsonb_build_object(
            'reason', p_reason,
            'purchase_number', v_purchase.purchase_number
        )
    );

    RETURN jsonb_build_object('success', true, 'message', 'Compra anulada y stock devuelto');
END;
$$;

-- 4. FUNCIÓN PARA REGISTRAR PAGO A PROVEEDOR
CREATE OR REPLACE FUNCTION register_supplier_payment(
    p_supplier_id UUID,
    p_amount NUMERIC(15,2),
    p_payment_method TEXT,
    p_reference TEXT,
    p_notes TEXT,
    p_user_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_payment_id UUID;
    v_new_debt NUMERIC(15,2);
BEGIN
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'El monto del pago debe ser mayor a cero';
    END IF;

    INSERT INTO supplier_payments (
        supplier_id,
        amount,
        payment_method,
        reference,
        notes,
        paid_by,
        created_at
    ) VALUES (
        p_supplier_id,
        p_amount,
        p_payment_method::payment_method_type,
        p_reference,
        p_notes,
        p_user_id,
        NOW()
    ) RETURNING id INTO v_payment_id;

    -- Disminuir deuda del proveedor
    UPDATE suppliers
    SET current_debt = GREATEST(0.00, current_debt - p_amount),
        updated_at = NOW()
    WHERE id = p_supplier_id
    RETURNING current_debt INTO v_new_debt;

    RETURN jsonb_build_object(
        'success', true,
        'payment_id', v_payment_id,
        'remaining_debt', v_new_debt
    );
END;
$$;
