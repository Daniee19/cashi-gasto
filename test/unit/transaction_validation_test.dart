import 'package:flutter_test/flutter_test.dart';

/// =============================================================================
/// 3.3.1. PRUEBAS UNITARIAS - Validacion de Campos de Transaccion
/// =============================================================================
/// Validar que cada campo (monto, categoria, fecha) cumpla con las reglas de
/// formato, tipo de dato y obligatoriedad antes de ser almacenado.
/// =============================================================================

/// Clase de validacion para campos de transaccion
class TransactionValidator {
  /// Valida el monto de la transaccion
  /// - No puede ser nulo o vacio
  /// - Debe ser un numero valido
  /// - Debe ser mayor a 0
  /// - No puede ser negativo
  static ValidationResult validateAmount(String? amount) {
    if (amount == null || amount.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'El monto es obligatorio',
      );
    }

    final parsedAmount = double.tryParse(amount);
    if (parsedAmount == null) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'El monto debe ser un numero valido',
      );
    }

    if (parsedAmount <= 0) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'El monto debe ser mayor a cero',
      );
    }

    if (parsedAmount < 0) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'El monto no puede ser negativo',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Valida la categoria de la transaccion
  /// - No puede ser nula
  /// - Debe existir en la lista de categorias permitidas
  static ValidationResult validateCategory(
    String? categoryId,
    List<String> allowedCategories,
  ) {
    if (categoryId == null || categoryId.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'La categoria es obligatoria',
      );
    }

    if (!allowedCategories.contains(categoryId)) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Categoria no permitida',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Valida la fecha de la transaccion
  /// - No puede ser nula
  /// - No puede ser una fecha futura
  /// - Debe ser una fecha valida
  static ValidationResult validateDate(DateTime? date) {
    if (date == null) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'La fecha es obligatoria',
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (date.isAfter(today)) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'La fecha no puede ser futura',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Valida todos los campos de una transaccion
  static ValidationResult validateTransaction({
    required String? amount,
    required String? categoryId,
    required DateTime? date,
    required List<String> allowedCategories,
  }) {
    // Validar monto
    final amountResult = validateAmount(amount);
    if (!amountResult.isValid) return amountResult;

    // Validar categoria
    final categoryResult = validateCategory(categoryId, allowedCategories);
    if (!categoryResult.isValid) return categoryResult;

    // Validar fecha
    final dateResult = validateDate(date);
    if (!dateResult.isValid) return dateResult;

    return ValidationResult(isValid: true);
  }
}

/// Resultado de validacion
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  ValidationResult({
    required this.isValid,
    this.errorMessage,
  });
}

void main() {
  group('3.3.1. Pruebas Unitarias - Validacion de Campos', () {
    // =========================================================================
    // PRUEBAS DE VALIDACION DE MONTO
    // =========================================================================
    group('Validacion de Monto', () {
      test('RECHAZA monto vacio', () {
        final result = TransactionValidator.validateAmount('');

        expect(result.isValid, false);
        expect(result.errorMessage, 'El monto es obligatorio');
        print('✓ Monto vacio rechazado correctamente');
      });

      test('RECHAZA monto nulo', () {
        final result = TransactionValidator.validateAmount(null);

        expect(result.isValid, false);
        expect(result.errorMessage, 'El monto es obligatorio');
        print('✓ Monto nulo rechazado correctamente');
      });

      test('RECHAZA monto con texto invalido', () {
        final result = TransactionValidator.validateAmount('abc');

        expect(result.isValid, false);
        expect(result.errorMessage, 'El monto debe ser un numero valido');
        print('✓ Monto con texto invalido rechazado correctamente');
      });

      test('RECHAZA monto negativo', () {
        final result = TransactionValidator.validateAmount('-50.00');

        expect(result.isValid, false);
        expect(result.errorMessage, 'El monto debe ser mayor a cero');
        print('✓ Monto negativo rechazado correctamente');
      });

      test('RECHAZA monto igual a cero', () {
        final result = TransactionValidator.validateAmount('0');

        expect(result.isValid, false);
        expect(result.errorMessage, 'El monto debe ser mayor a cero');
        print('✓ Monto cero rechazado correctamente');
      });

      test('ACEPTA monto valido positivo', () {
        final result = TransactionValidator.validateAmount('150.50');

        expect(result.isValid, true);
        expect(result.errorMessage, isNull);
        print('✓ Monto valido S/ 150.50 aceptado correctamente');
      });

      test('ACEPTA monto entero valido', () {
        final result = TransactionValidator.validateAmount('100');

        expect(result.isValid, true);
        print('✓ Monto entero S/ 100 aceptado correctamente');
      });
    });

    // =========================================================================
    // PRUEBAS DE VALIDACION DE CATEGORIA
    // =========================================================================
    group('Validacion de Categoria', () {
      final categoriasPermitidas = [
        'cat-alimentacion',
        'cat-transporte',
        'cat-entretenimiento',
        'cat-salud',
        'cat-educacion',
      ];

      test('RECHAZA categoria vacia', () {
        final result = TransactionValidator.validateCategory(
          '',
          categoriasPermitidas,
        );

        expect(result.isValid, false);
        expect(result.errorMessage, 'La categoria es obligatoria');
        print('✓ Categoria vacia rechazada correctamente');
      });

      test('RECHAZA categoria nula', () {
        final result = TransactionValidator.validateCategory(
          null,
          categoriasPermitidas,
        );

        expect(result.isValid, false);
        expect(result.errorMessage, 'La categoria es obligatoria');
        print('✓ Categoria nula rechazada correctamente');
      });

      test('RECHAZA categoria no permitida', () {
        final result = TransactionValidator.validateCategory(
          'cat-inexistente',
          categoriasPermitidas,
        );

        expect(result.isValid, false);
        expect(result.errorMessage, 'Categoria no permitida');
        print('✓ Categoria no permitida rechazada correctamente');
      });

      test('ACEPTA categoria valida - Alimentacion', () {
        final result = TransactionValidator.validateCategory(
          'cat-alimentacion',
          categoriasPermitidas,
        );

        expect(result.isValid, true);
        print('✓ Categoria "Alimentacion" aceptada correctamente');
      });

      test('ACEPTA categoria valida - Transporte', () {
        final result = TransactionValidator.validateCategory(
          'cat-transporte',
          categoriasPermitidas,
        );

        expect(result.isValid, true);
        print('✓ Categoria "Transporte" aceptada correctamente');
      });
    });

    // =========================================================================
    // PRUEBAS DE VALIDACION DE FECHA
    // =========================================================================
    group('Validacion de Fecha', () {
      test('RECHAZA fecha nula', () {
        final result = TransactionValidator.validateDate(null);

        expect(result.isValid, false);
        expect(result.errorMessage, 'La fecha es obligatoria');
        print('✓ Fecha nula rechazada correctamente');
      });

      test('RECHAZA fecha futura', () {
        final fechaFutura = DateTime.now().add(const Duration(days: 5));
        final result = TransactionValidator.validateDate(fechaFutura);

        expect(result.isValid, false);
        expect(result.errorMessage, 'La fecha no puede ser futura');
        print('✓ Fecha futura rechazada correctamente');
      });

      test('ACEPTA fecha de hoy', () {
        final hoy = DateTime.now();
        final result = TransactionValidator.validateDate(hoy);

        expect(result.isValid, true);
        print('✓ Fecha de hoy aceptada correctamente');
      });

      test('ACEPTA fecha pasada', () {
        final fechaPasada = DateTime.now().subtract(const Duration(days: 30));
        final result = TransactionValidator.validateDate(fechaPasada);

        expect(result.isValid, true);
        print('✓ Fecha pasada (hace 30 dias) aceptada correctamente');
      });
    });

    // =========================================================================
    // PRUEBAS DE VALIDACION COMPLETA DE TRANSACCION
    // =========================================================================
    group('Validacion Completa de Transaccion', () {
      final categoriasPermitidas = [
        'cat-alimentacion',
        'cat-transporte',
      ];

      test('RECHAZA transaccion con todos los campos vacios', () {
        final result = TransactionValidator.validateTransaction(
          amount: null,
          categoryId: null,
          date: null,
          allowedCategories: categoriasPermitidas,
        );

        expect(result.isValid, false);
        print('✓ Transaccion con campos vacios rechazada');
      });

      test('RECHAZA transaccion con monto invalido', () {
        final result = TransactionValidator.validateTransaction(
          amount: '-100',
          categoryId: 'cat-alimentacion',
          date: DateTime.now(),
          allowedCategories: categoriasPermitidas,
        );

        expect(result.isValid, false);
        expect(result.errorMessage, 'El monto debe ser mayor a cero');
        print('✓ Transaccion con monto negativo rechazada');
      });

      test('RECHAZA transaccion con categoria invalida', () {
        final result = TransactionValidator.validateTransaction(
          amount: '50.00',
          categoryId: 'cat-inexistente',
          date: DateTime.now(),
          allowedCategories: categoriasPermitidas,
        );

        expect(result.isValid, false);
        expect(result.errorMessage, 'Categoria no permitida');
        print('✓ Transaccion con categoria invalida rechazada');
      });

      test('RECHAZA transaccion con fecha futura', () {
        final result = TransactionValidator.validateTransaction(
          amount: '50.00',
          categoryId: 'cat-alimentacion',
          date: DateTime.now().add(const Duration(days: 10)),
          allowedCategories: categoriasPermitidas,
        );

        expect(result.isValid, false);
        expect(result.errorMessage, 'La fecha no puede ser futura');
        print('✓ Transaccion con fecha futura rechazada');
      });

      test('ACEPTA transaccion con todos los campos validos', () {
        final result = TransactionValidator.validateTransaction(
          amount: '150.00',
          categoryId: 'cat-alimentacion',
          date: DateTime.now(),
          allowedCategories: categoriasPermitidas,
        );

        expect(result.isValid, true);
        expect(result.errorMessage, isNull);
        print('✓ Transaccion valida aceptada correctamente');
        print('  - Monto: S/ 150.00');
        print('  - Categoria: Alimentacion');
        print('  - Fecha: Hoy');
      });
    });
  });
}
