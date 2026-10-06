-- ==============================================================================
-- MIGRATION: 20261006_dashboard_metrics_rpc.sql
-- DESCRIPTION: Atomic RPC function to load all business metrics for Dashboard
-- ==============================================================================

CREATE OR REPLACE FUNCTION get_dashboard_metrics()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_sales_today numeric := 0;
  v_sales_week numeric := 0;
  v_sales_month numeric := 0;
  v_total_cxc numeric := 0;
  v_total_cxp numeric := 0;
  v_total_income numeric := 0;
  v_total_expenses numeric := 0;
  v_low_stock json;
  v_recent_sales json;
  v_weekly_trend json;
  v_result json;
BEGIN
  -- 1. Ventas hoy
  SELECT COALESCE(SUM(total_amount), 0) INTO v_sales_today
  FROM sales
  WHERE status = 'completed' AND created_at >= CURRENT_DATE;

  -- 2. Ventas esta semana
  SELECT COALESCE(SUM(total_amount), 0) INTO v_sales_week
  FROM sales
  WHERE status = 'completed' AND created_at >= date_trunc('week', CURRENT_DATE);

  -- 3. Ventas este mes
  SELECT COALESCE(SUM(total_amount), 0) INTO v_sales_month
  FROM sales
  WHERE status = 'completed' AND created_at >= date_trunc('month', CURRENT_DATE);

  -- 4. Total Ingresos
  SELECT COALESCE(SUM(total_amount), 0) INTO v_total_income
  FROM sales
  WHERE status = 'completed';

  -- 5. Cuentas por Cobrar (Clientes)
  SELECT COALESCE(SUM(current_balance), 0) INTO v_total_cxc
  FROM customers;

  -- 6. Cuentas por Pagar (Compras pendientes de pago que no hayan sido canceladas)
  SELECT COALESCE(SUM(total_amount), 0) INTO v_total_cxp
  FROM purchases
  WHERE payment_status = 'pending' AND status != 'cancelled';

  -- 7. Gastos totales
  SELECT COALESCE(SUM(amount), 0) INTO v_total_expenses
  FROM expenses;

  -- 8. Productos con bajo stock
  SELECT COALESCE(json_agg(p), '[]'::json) INTO v_low_stock
  FROM (
    SELECT product_id AS id, product_name AS name, COALESCE(sku, '') AS sku, current_stock, min_stock
    FROM v_inventory_overview
    WHERE current_stock <= min_stock
    ORDER BY current_stock ASC
    LIMIT 6
  ) p;

  -- 9. Ventas recientes
  SELECT COALESCE(json_agg(s), '[]'::json) INTO v_recent_sales
  FROM (
    SELECT id, invoice_number, COALESCE(customer_name, 'Consumidor Final') AS customer_name, total_amount, payment_method, created_at
    FROM v_sales_summary
    WHERE status = 'completed'
    ORDER BY created_at DESC
    LIMIT 6
  ) s;

  -- 10. Tendencia de ventas de los últimos 7 días
  SELECT COALESCE(json_agg(daily.amount), '[0,0,0,0,0,0,0]'::json) INTO v_weekly_trend
  FROM (
    SELECT 
      d.day::date,
      COALESCE(SUM(s.total_amount), 0) AS amount
    FROM generate_series(CURRENT_DATE - INTERVAL '6 days', CURRENT_DATE, '1 day'::interval) d(day)
    LEFT JOIN sales s ON s.created_at::date = d.day::date AND s.status = 'completed'
    GROUP BY d.day
    ORDER BY d.day ASC
  ) daily;

  v_result := json_build_object(
    'sales_today', v_sales_today,
    'sales_week', v_sales_week,
    'sales_month', v_sales_month,
    'total_income', v_total_income,
    'total_expenses', v_total_expenses,
    'net_profit', (v_total_income - v_total_expenses),
    'accounts_receivable', v_total_cxc,
    'accounts_payable', v_total_cxp,
    'low_stock_products', v_low_stock,
    'recent_sales', v_recent_sales,
    'weekly_sales_trend', v_weekly_trend
  );

  RETURN v_result;
END;
$$;
