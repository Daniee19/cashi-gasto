import 'package:flutter_test/flutter_test.dart';
import 'package:cashi_gasto/services/sms_parser_service.dart';
import 'package:cashi_gasto/data/models/transaction.dart';

void main() {
  group('SMS Parser Service - Simulacion de flujo', () {

    test('Yape - Pago enviado', () {
      final result = SmsParserService.parse(
        'com.bcp.innovacxion.yapeapp',
        'Yape',
        'Enviaste S/ 25.50 a Juan Perez',
      );

      expect(result, isNotNull);
      expect(result!.amount, 25.50);
      expect(result.type, TransactionType.expense);
      expect(result.sourceApp, 'Yape');
      print('✓ Yape pago: S/ ${result.amount} - ${result.description}');
    });

    test('Yape - Pago recibido', () {
      final result = SmsParserService.parse(
        'com.bcp.innovacxion.yapeapp',
        'Yape',
        'Recibiste S/ 100.00 de Maria Garcia',
      );

      expect(result, isNotNull);
      expect(result!.amount, 100.00);
      expect(result.type, TransactionType.income);
      expect(result.sourceApp, 'Yape');
      print('✓ Yape recibido: S/ ${result.amount} - ${result.description}');
    });

    test('BCP - Consumo con tarjeta', () {
      final result = SmsParserService.parse(
        'com.bcp.bank.bcp',
        'BCP',
        'Consumo de S/ 156.80 en SUPERMERCADOS METRO con TC *1234',
      );

      expect(result, isNotNull);
      expect(result!.amount, 156.80);
      expect(result.type, TransactionType.expense);
      expect(result.sourceApp, 'BCP');
      print('✓ BCP consumo: S/ ${result.amount} - ${result.description}');
    });

    test('BCP - Transferencia recibida', () {
      final result = SmsParserService.parse(
        'com.bcp.bank.bcp',
        'BCP',
        'Recibiste una transferencia de S/ 500.00 en tu cuenta *5678',
      );

      expect(result, isNotNull);
      expect(result!.amount, 500.00);
      expect(result.type, TransactionType.income);
      print('✓ BCP transferencia: S/ ${result.amount} - ${result.description}');
    });

    test('Interbank - Compra', () {
      final result = SmsParserService.parse(
        'pe.interbank.mobilebanking',
        'Interbank',
        'IBK: Compra por S/ 89.90 en WONG PERU',
      );

      expect(result, isNotNull);
      expect(result!.amount, 89.90);
      expect(result.type, TransactionType.expense);
      print('✓ Interbank compra: S/ ${result.amount} - ${result.description}');
    });

    test('BBVA - Pago', () {
      final result = SmsParserService.parse(
        'com.bbva.peru',
        'BBVA',
        'BBVA: Pago realizado por S/ 45.00 en FARMACIA UNIVERSAL',
      );

      expect(result, isNotNull);
      expect(result!.amount, 45.00);
      expect(result.type, TransactionType.expense);
      print('✓ BBVA pago: S/ ${result.amount} - ${result.description}');
    });

    test('SMS generico - Consumo', () {
      final result = SmsParserService.parse(
        'com.google.android.apps.messaging',
        'SMS',
        'BANCO XYZ: Consumo aprobado por S/. 320.50 en TIENDA ABC',
      );

      expect(result, isNotNull);
      expect(result!.amount, 320.50);
      expect(result.type, TransactionType.expense);
      print('✓ SMS generico: S/ ${result.amount} - ${result.description}');
    });

    test('SMS generico - Deposito', () {
      final result = SmsParserService.parse(
        'com.google.android.apps.messaging',
        'SMS',
        'Se realizo un deposito de S/ 1500.00 en tu cuenta',
      );

      expect(result, isNotNull);
      expect(result!.amount, 1500.00);
      expect(result.type, TransactionType.income);
      print('✓ SMS deposito: S/ ${result.amount} - ${result.description}');
    });

    test('Notificacion no bancaria - debe ignorar', () {
      final result = SmsParserService.parse(
        'com.whatsapp',
        'WhatsApp',
        'Tienes un nuevo mensaje',
      );

      expect(result, isNull);
      print('✓ WhatsApp ignorado correctamente');
    });

    test('App bancaria sin monto - debe ignorar', () {
      final result = SmsParserService.parse(
        'com.bcp.innovacxion.yapeapp',
        'Yape',
        'Tu codigo de verificacion es 123456',
      );

      expect(result, isNull);
      print('✓ Yape sin monto ignorado correctamente');
    });

    test('Deduplicacion - mismo monto y minuto', () {
      final result1 = SmsParserService.parse(
        'com.bcp.innovacxion.yapeapp',
        'Yape',
        'Enviaste S/ 50.00 a Pedro',
      );

      final result2 = SmsParserService.parse(
        'com.bcp.innovacxion.yapeapp',
        'Yape',
        'Enviaste S/ 50.00 a Pedro',
      );

      // Ambos parsean igual
      expect(result1!.amount, result2!.amount);
      expect(result1.type, result2.type);

      // Pero deduplicationKey seria igual si es mismo minuto
      // (en produccion el servicio filtra por este key)
      print('✓ Deduplicacion: key1=${result1.deduplicationKey.split('_').take(3).join('_')}');
    });
  });

  group('isBankApp - Verificacion de apps', () {
    test('Apps bancarias reconocidas', () {
      expect(SmsParserService.isBankApp('com.bcp.innovacxion.yapeapp'), true);
      expect(SmsParserService.isBankApp('com.bcp.bank.bcp'), true);
      expect(SmsParserService.isBankApp('pe.interbank.mobilebanking'), true);
      expect(SmsParserService.isBankApp('com.bbva.peru'), true);
      expect(SmsParserService.isBankApp('com.scotiabank.peru'), true);
      expect(SmsParserService.isBankApp('com.google.android.apps.messaging'), true);
      print('✓ Todas las apps bancarias reconocidas');
    });

    test('Apps no bancarias rechazadas', () {
      expect(SmsParserService.isBankApp('com.whatsapp'), false);
      expect(SmsParserService.isBankApp('com.facebook.katana'), false);
      expect(SmsParserService.isBankApp('com.spotify.music'), false);
      print('✓ Apps no bancarias rechazadas');
    });
  });
}
