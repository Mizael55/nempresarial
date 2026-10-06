import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';
import '../widgets/nubiko_responsive_layout.dart';
import 'app_bottom_nav.dart';
import 'app_sidebar.dart';
import 'app_topbar.dart';

class MainLayoutScaffold extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const MainLayoutScaffold({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  State<MainLayoutScaffold> createState() => _MainLayoutScaffoldState();
}

class _MainLayoutScaffoldState extends State<MainLayoutScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550, maxHeight: 420),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    autofocus: true,
                    style: AppTypography.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Buscar productos, clientes, facturas o comandos...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: AppRadius.roundedMd),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.add_shopping_cart, color: AppColors.primary500),
                          title: const Text('Nueva Venta rápida (POS)'),
                          subtitle: const Text('Comenzar transacción en caja'),
                          trailing: const Text('⌘ N'),
                          onTap: () => Navigator.pop(context),
                        ),
                        ListTile(
                          leading: const Icon(Icons.inventory_2_outlined, color: AppColors.emerald500),
                          title: const Text('Crear Nuevo Producto'),
                          subtitle: const Text('Agregar artículo al catálogo'),
                          onTap: () => Navigator.pop(context),
                        ),
                        ListTile(
                          leading: const Icon(Icons.person_add_outlined, color: AppColors.amber500),
                          title: const Text('Registrar Cliente'),
                          subtitle: const Text('Nuevo cliente o cuenta por cobrar'),
                          onTap: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK): const ActivateIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<Intent>(
            onInvoke: (intent) => _openSearchDialog(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: NubikoResponsiveLayout(
            // Mobile layout
            mobile: Scaffold(
              key: _scaffoldKey,
              drawer: Drawer(
                child: AppSidebar(currentRoute: widget.currentRoute),
              ),
              appBar: AppTopbar(
                onSearchTap: _openSearchDialog,
                onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              body: widget.child,
              bottomNavigationBar: AppBottomNav(currentRoute: widget.currentRoute),
            ),
            // Desktop layout with persistent modern sidebar
            desktop: Scaffold(
              body: Row(
                children: [
                  AppSidebar(currentRoute: widget.currentRoute),
                  Expanded(
                    child: Column(
                      children: [
                        AppTopbar(onSearchTap: _openSearchDialog),
                        Expanded(child: widget.child),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
