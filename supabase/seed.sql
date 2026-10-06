-- ============================================================================
-- NUBIKO ENTERPRISE - INITIAL SEED DATA
-- ============================================================================

-- 1. Main Branch
INSERT INTO branches (id, name, code, address, phone, is_main, is_active)
VALUES (
    'a0000000-0000-0000-0000-000000000001',
    'Sucursal Principal',
    'SUC-001',
    'Sede Central',
    '+1 (809) 555-0100',
    true,
    true
) ON CONFLICT (code) DO NOTHING;

-- 2. System Roles
INSERT INTO roles (name, display_name, description, is_system)
VALUES 
    ('super_admin', 'Super Administrador', 'Acceso total y configuración del sistema', true),
    ('admin', 'Administrador', 'Gestión operativa y reportes', true),
    ('manager', 'Gerente de Sucursal', 'Supervisión de sucursal, inventario y caja', true),
    ('cashier', 'Cajero / POS', 'Apertura de caja, ventas y cobros', true),
    ('inventory_clerk', 'Encargado de Inventario', 'Recepción de compras y ajustes de stock', true),
    ('sales_rep', 'Representante de Ventas', 'Emisión de cotizaciones y pedidos', true)
ON CONFLICT (name) DO NOTHING;

-- 3. Product Categories
INSERT INTO product_categories (id, name, description, icon, color, is_active)
VALUES 
    ('c0000000-0000-0000-0000-000000000001', 'Alimentos & Abarrotes', 'Aceites, enlatados, condimentos y abarrotes', 'shoppingBag', '#3B82F6', true),
    ('c0000000-0000-0000-0000-000000000002', 'Bebidas', 'Refrescos, jugos, aguas y licores', 'coffee', '#10B981', true),
    ('c0000000-0000-0000-0000-000000000003', 'Lácteos & Refrigerados', 'Leches, quesos, yogures y embutidos', 'package', '#F59E0B', true),
    ('c0000000-0000-0000-0000-000000000004', 'Granos & Cereales', 'Arroz, habichuelas, avena, harinas', 'boxes', '#8B5CF6', true),
    ('c0000000-0000-0000-0000-000000000005', 'Limpieza & Hogar', 'Detergentes, desinfectantes y papel', 'sparkles', '#06B6D4', true),
    ('c0000000-0000-0000-0000-000000000006', 'Tecnología & Accesorios', 'Cables, cargadores y dispositivos', 'laptop', '#EC4899', true),
    ('c0000000-0000-0000-0000-000000000007', 'Otros / General', 'Artículos varios no clasificados', 'tag', '#64748B', true)
ON CONFLICT DO NOTHING;

-- 4. Initial Expense Categories
INSERT INTO expense_categories (name, description, color, is_active)
VALUES 
    ('Alquiler de Local', 'Pago mensual de arrendamiento inmobiliario', '#EF4444', true),
    ('Electricidad & Energía', 'Servicio eléctrico comercial', '#F59E0B', true),
    ('Internet & Telecomunicaciones', 'Servicio de fibra óptica y telefonía', '#3B82F6', true),
    ('Agua Potable & Servicios', 'Suministro y mantenimiento de agua', '#06B6D4', true),
    ('Salarios & Nómina', 'Pago a colaboradores y comisiones', '#10B981', true),
    ('Transporte & Combustible', 'Fletes, envíos y logística', '#8B5CF6', true),
    ('Mantenimiento & Reparaciones', 'Reparación de equipos e infraestructura', '#F97316', true),
    ('Publicidad & Marketing', 'Campañas digitales e impresas', '#EC4899', true),
    ('Otros Gastos', 'Gastos misceláneos de operación', '#64748B', true)
ON CONFLICT DO NOTHING;

-- 5. Default Cash Register for Main Branch
INSERT INTO cash_registers (name, code, branch_id, is_active)
VALUES (
    'Caja Principal 01',
    'POS-01',
    'a0000000-0000-0000-0000-000000000001',
    true
) ON CONFLICT DO NOTHING;
