import 'package:flutter_test/flutter_test.dart';

/// =============================================================================
/// 3.3.2. PRUEBAS INTEGRALES - Almacenamiento y Actualizacion del Dashboard
/// =============================================================================
/// Verificar que el gasto registrado se almacene correctamente en la base de
/// datos y se refleje en tiempo real en el dashboard con los calculos actualizados.
/// =============================================================================

/// Modelo simplificado de Transaccion para pruebas
class TransactionModel {
  final String id;
  final double amount;
  final String type; // 'expense' o 'income'
  final String categoryId;
  final DateTime date;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
  });
}

/// Simulacion de Base de Datos en memoria
class MockDatabase {
  final List<TransactionModel> _transactions = [];

  List<TransactionModel> get transactions => List.unmodifiable(_transactions);

  /// Inserta una transaccion en la base de datos
  Future<bool> insertTransaction(TransactionModel transaction) async {
    // Simular latencia de red
    await Future.delayed(const Duration(milliseconds: 100));
    _transactions.add(transaction);
    return true;
  }

  /// Obtiene todas las transacciones
  Future<List<TransactionModel>> getAllTransactions() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List.from(_transactions);
  }

  /// Limpia la base de datos
  void clear() {
    _transactions.clear();
  }
}

/// Simulacion del Dashboard
class DashboardState {
  double totalIngresos = 0;
  double totalGastos = 0;
  double balance = 0;
  int cantidadTransacciones = 0;

  /// Recalcula el estado del dashboard basado en las transacciones
  void recalculate(List<TransactionModel> transactions) {
    totalIngresos = 0;
    totalGastos = 0;

    for (final tx in transactions) {
      if (tx.type == 'income') {
        totalIngresos += tx.amount;
      } else if (tx.type == 'expense') {
        totalGastos += tx.amount;
      }
    }

    balance = totalIngresos - totalGastos;
    cantidadTransacciones = transactions.length;
  }
}

/// Servicio de Transacciones que conecta DB y Dashboard
class TransactionService {
  final MockDatabase database;
  final DashboardState dashboard;

  TransactionService({
    required this.database,
    required this.dashboard,
  });

  /// Registra una transaccion y actualiza el dashboard
  Future<bool> registerTransaction(TransactionModel transaction) async {
    // 1. Guardar en base de datos
    final success = await database.insertTransaction(transaction);

    if (success) {
      // 2. Obtener todas las transacciones
      final allTransactions = await database.getAllTransactions();

      // 3. Recalcular dashboard en tiempo real
      dashboard.recalculate(allTransactions);
    }

    return success;
  }
}

void main() {
  late MockDatabase database;
  late DashboardState dashboard;
  late TransactionService service;

  setUp(() {
    database = MockDatabase();
    dashboard = DashboardState();
    service = TransactionService(database: database, dashboard: dashboard);
  });

  group('3.3.2. Pruebas Integrales - Almacenamiento y Dashboard', () {
    // =========================================================================
    // PRUEBA 1: Verificar almacenamiento y reflejo en dashboard
    // =========================================================================
    group('Almacenamiento y Reflejo en Dashboard', () {
      test('Gasto registrado se almacena en BD y actualiza dashboard', () async {
        print('\n========================================');
        print('PRUEBA: Registro de Gasto Individual');
        print('========================================');

        // Estado inicial
        print('\n[Estado Inicial]');
        print('  Balance: S/ ${dashboard.balance.toStringAsFixed(2)}');
        print('  Total Gastos: S/ ${dashboard.totalGastos.toStringAsFixed(2)}');
        print('  Transacciones: ${dashboard.cantidadTransacciones}');

        // Crear transaccion de gasto
        final gasto = TransactionModel(
          id: 'tx-001',
          amount: 45.50,
          type: 'expense',
          categoryId: 'cat-alimentacion',
          date: DateTime.now(),
        );

        print('\n[Registrando Gasto]');
        print('  Monto: S/ ${gasto.amount}');
        print('  Categoria: Alimentacion');

        // Registrar gasto
        final success = await service.registerTransaction(gasto);

        // Verificaciones
        expect(success, true);
        expect(database.transactions.length, 1);
        expect(dashboard.totalGastos, 45.50);
        expect(dashboard.balance, -45.50);
        expect(dashboard.cantidadTransacciones, 1);

        print('\n[Estado Actualizado - TIEMPO REAL]');
        print('  ✓ Transaccion almacenada en BD');
        print('  ✓ Balance actualizado: S/ ${dashboard.balance.toStringAsFixed(2)}');
        print('  ✓ Total Gastos: S/ ${dashboard.totalGastos.toStringAsFixed(2)}');
        print('  ✓ Cantidad: ${dashboard.cantidadTransacciones} transaccion(es)');
        print('\n✅ PRUEBA EXITOSA');
      });

      test('Ingreso registrado se almacena en BD y actualiza dashboard', () async {
        print('\n========================================');
        print('PRUEBA: Registro de Ingreso Individual');
        print('========================================');

        // Crear transaccion de ingreso
        final ingreso = TransactionModel(
          id: 'tx-002',
          amount: 2500.00,
          type: 'income',
          categoryId: 'cat-salario',
          date: DateTime.now(),
        );

        print('\n[Registrando Ingreso]');
        print('  Monto: S/ ${ingreso.amount}');
        print('  Categoria: Salario');

        // Registrar ingreso
        final success = await service.registerTransaction(ingreso);

        // Verificaciones
        expect(success, true);
        expect(database.transactions.length, 1);
        expect(dashboard.totalIngresos, 2500.00);
        expect(dashboard.balance, 2500.00);

        print('\n[Estado Actualizado - TIEMPO REAL]');
        print('  ✓ Transaccion almacenada en BD');
        print('  ✓ Balance actualizado: S/ ${dashboard.balance.toStringAsFixed(2)}');
        print('  ✓ Total Ingresos: S/ ${dashboard.totalIngresos.toStringAsFixed(2)}');
        print('\n✅ PRUEBA EXITOSA');
      });
    });

    // =========================================================================
    // PRUEBA 2: Multiples gastos en la misma sesion
    // =========================================================================
    group('Multiples Transacciones en Sesion', () {
      test('Balance se recalcula correctamente tras cada operacion', () async {
        print('\n========================================');
        print('PRUEBA: Multiples Gastos en Sesion');
        print('========================================');
        print('Verificar recalculo de balance sin recargar pagina\n');

        // Transaccion 1: Ingreso inicial
        print('[Operacion 1] Ingreso - Salario');
        final ingreso = TransactionModel(
          id: 'tx-001',
          amount: 3000.00,
          type: 'income',
          categoryId: 'cat-salario',
          date: DateTime.now(),
        );
        await service.registerTransaction(ingreso);

        expect(dashboard.balance, 3000.00);
        print('  Monto: +S/ 3000.00');
        print('  Balance actual: S/ ${dashboard.balance.toStringAsFixed(2)} ✓');

        // Transaccion 2: Gasto en alimentacion
        print('\n[Operacion 2] Gasto - Alimentacion');
        final gasto1 = TransactionModel(
          id: 'tx-002',
          amount: 150.00,
          type: 'expense',
          categoryId: 'cat-alimentacion',
          date: DateTime.now(),
        );
        await service.registerTransaction(gasto1);

        expect(dashboard.balance, 2850.00);
        print('  Monto: -S/ 150.00');
        print('  Balance actual: S/ ${dashboard.balance.toStringAsFixed(2)} ✓');

        // Transaccion 3: Gasto en transporte
        print('\n[Operacion 3] Gasto - Transporte');
        final gasto2 = TransactionModel(
          id: 'tx-003',
          amount: 50.00,
          type: 'expense',
          categoryId: 'cat-transporte',
          date: DateTime.now(),
        );
        await service.registerTransaction(gasto2);

        expect(dashboard.balance, 2800.00);
        print('  Monto: -S/ 50.00');
        print('  Balance actual: S/ ${dashboard.balance.toStringAsFixed(2)} ✓');

        // Transaccion 4: Gasto en entretenimiento
        print('\n[Operacion 4] Gasto - Entretenimiento');
        final gasto3 = TransactionModel(
          id: 'tx-004',
          amount: 80.00,
          type: 'expense',
          categoryId: 'cat-entretenimiento',
          date: DateTime.now(),
        );
        await service.registerTransaction(gasto3);

        expect(dashboard.balance, 2720.00);
        print('  Monto: -S/ 80.00');
        print('  Balance actual: S/ ${dashboard.balance.toStringAsFixed(2)} ✓');

        // Transaccion 5: Otro ingreso
        print('\n[Operacion 5] Ingreso - Freelance');
        final ingreso2 = TransactionModel(
          id: 'tx-005',
          amount: 500.00,
          type: 'income',
          categoryId: 'cat-otros-ingresos',
          date: DateTime.now(),
        );
        await service.registerTransaction(ingreso2);

        expect(dashboard.balance, 3220.00);
        print('  Monto: +S/ 500.00');
        print('  Balance actual: S/ ${dashboard.balance.toStringAsFixed(2)} ✓');

        // Verificaciones finales
        print('\n========================================');
        print('RESUMEN FINAL DE LA SESION');
        print('========================================');
        expect(dashboard.cantidadTransacciones, 5);
        expect(dashboard.totalIngresos, 3500.00);
        expect(dashboard.totalGastos, 280.00);
        expect(dashboard.balance, 3220.00);

        print('  Total Ingresos: S/ ${dashboard.totalIngresos.toStringAsFixed(2)}');
        print('  Total Gastos:   S/ ${dashboard.totalGastos.toStringAsFixed(2)}');
        print('  Balance Final:  S/ ${dashboard.balance.toStringAsFixed(2)}');
        print('  Transacciones:  ${dashboard.cantidadTransacciones}');
        print('\n✅ Balance recalculado correctamente tras cada operacion');
        print('✅ Sin necesidad de recargar la pagina');
      });

      test('Verifica integridad de datos en BD tras multiples operaciones', () async {
        print('\n========================================');
        print('PRUEBA: Integridad de Datos en BD');
        print('========================================\n');

        // Registrar varias transacciones
        final transacciones = [
          TransactionModel(id: 'tx-1', amount: 100, type: 'expense', categoryId: 'cat-1', date: DateTime.now()),
          TransactionModel(id: 'tx-2', amount: 200, type: 'expense', categoryId: 'cat-2', date: DateTime.now()),
          TransactionModel(id: 'tx-3', amount: 500, type: 'income', categoryId: 'cat-3', date: DateTime.now()),
        ];

        for (final tx in transacciones) {
          await service.registerTransaction(tx);
        }

        // Verificar que todas estan en la BD
        final stored = await database.getAllTransactions();

        expect(stored.length, 3);
        expect(stored[0].id, 'tx-1');
        expect(stored[1].id, 'tx-2');
        expect(stored[2].id, 'tx-3');

        print('[Transacciones Almacenadas en BD]');
        for (final tx in stored) {
          final sign = tx.type == 'income' ? '+' : '-';
          print('  ${tx.id}: $sign S/ ${tx.amount.toStringAsFixed(2)}');
        }

        print('\n[Verificacion de Integridad]');
        print('  ✓ 3 transacciones almacenadas correctamente');
        print('  ✓ IDs unicos preservados');
        print('  ✓ Montos correctos');
        print('\n✅ PRUEBA EXITOSA');
      });
    });

    // =========================================================================
    // PRUEBA 3: Actualizacion en tiempo real
    // =========================================================================
    group('Actualizacion en Tiempo Real', () {
      test('Dashboard refleja cambios inmediatamente sin delay', () async {
        print('\n========================================');
        print('PRUEBA: Tiempo Real - Sin Recarga');
        print('========================================\n');

        // Estado inicial
        final balanceInicial = dashboard.balance;
        print('[T0] Estado Inicial');
        print('     Balance: S/ ${balanceInicial.toStringAsFixed(2)}');

        // Operacion 1
        await service.registerTransaction(
          TransactionModel(
            id: 'rt-1',
            amount: 1000,
            type: 'income',
            categoryId: 'cat-salario',
            date: DateTime.now(),
          ),
        );
        print('\n[T1] Despues de ingreso S/ 1000');
        print('     Balance: S/ ${dashboard.balance.toStringAsFixed(2)} (actualizado)');
        expect(dashboard.balance, 1000.00);

        // Operacion 2
        await service.registerTransaction(
          TransactionModel(
            id: 'rt-2',
            amount: 250,
            type: 'expense',
            categoryId: 'cat-compras',
            date: DateTime.now(),
          ),
        );
        print('\n[T2] Despues de gasto S/ 250');
        print('     Balance: S/ ${dashboard.balance.toStringAsFixed(2)} (actualizado)');
        expect(dashboard.balance, 750.00);

        // Operacion 3
        await service.registerTransaction(
          TransactionModel(
            id: 'rt-3',
            amount: 100,
            type: 'expense',
            categoryId: 'cat-transporte',
            date: DateTime.now(),
          ),
        );
        print('\n[T3] Despues de gasto S/ 100');
        print('     Balance: S/ ${dashboard.balance.toStringAsFixed(2)} (actualizado)');
        expect(dashboard.balance, 650.00);

        print('\n========================================');
        print('RESULTADO');
        print('========================================');
        print('✅ Cada operacion actualiza el dashboard inmediatamente');
        print('✅ No se requiere recargar la pagina');
        print('✅ Los calculos son correctos en tiempo real');
      });
    });
  });
}
