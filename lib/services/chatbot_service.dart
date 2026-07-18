/// Servicio de chatbot de Cashito - respuestas simuladas sin IA
class ChatbotService {
  static final _random = DateTime.now().millisecondsSinceEpoch;

  /// Genera respuesta basada en el mensaje del usuario
  static String getResponse(String userMessage) {
    final lower = userMessage.toLowerCase().trim();

    // Saludos
    if (_matchesAny(lower, ['hola', 'hi', 'hey', 'buenas', 'buenos dias', 'buenas tardes', 'buenas noches', 'que tal'])) {
      return _randomFrom([
        'Miau! Hola! Soy Cashito, tu gatito financiero. En que puedo ayudarte hoy?',
        'Hola! *mueve la colita* Que gusto verte! Tienes alguna duda sobre tus finanzas?',
        'Miau miau! Bienvenido! Estoy aqui para ayudarte con tus gastos e ingresos.',
      ]);
    }

    // Despedidas
    if (_matchesAny(lower, ['adios', 'bye', 'chau', 'hasta luego', 'nos vemos', 'gracias'])) {
      return _randomFrom([
        'Miau! Hasta pronto! Recuerda revisar tus gastos diariamente.',
        'Adios! *ronronea* Cuida tu dinero como yo cuido mi atun!',
        'Nos vemos! Si necesitas algo, aqui estare acurrucado esperandote.',
      ]);
    }

    // Ahorro
    if (_matchesAny(lower, ['ahorrar', 'ahorro', 'guardar dinero', 'ahorros'])) {
      return _randomFrom([
        'Miau! El ahorro es como guardar croquetas para el invierno. Te recomiendo apartar al menos el 10% de tus ingresos apenas los recibas.',
        'Un buen gatito siempre tiene reservas! Intenta la regla 50/30/20: 50% necesidades, 30% gustos, 20% ahorro.',
        'Tip de Cashito: Crea una meta de ahorro en la app y ve tu progreso! Nada motiva mas que ver crecer tu alcancia.',
        'Para ahorrar, primero pagate a ti mismo. Apenas recibas dinero, transfiere algo a tu fondo de ahorro antes de gastar.',
      ]);
    }

    // Gastos
    if (_matchesAny(lower, ['gasto', 'gastos', 'gastar', 'gastando', 'gaste'])) {
      return _randomFrom([
        'Miau! Controlar los gastos es clave. Revisa tu historial en la app y busca los gastos hormiga que se comen tu dinero sin que te des cuenta.',
        'Los gastos pequenos se acumulan como pelos de gato en el sofa! Ese cafe diario de S/8 son S/240 al mes.',
        'Tip: Antes de comprar algo, preguntate: lo necesito o solo lo quiero? Espera 24 horas antes de compras impulsivas.',
        'Categoriza todos tus gastos en la app para saber exactamente a donde va tu dinero. El conocimiento es poder!',
      ]);
    }

    // Presupuesto
    if (_matchesAny(lower, ['presupuesto', 'presupuestos', 'budget', 'limite'])) {
      return _randomFrom([
        'Los presupuestos son como mi plato de comida: tienen limite! Crea presupuestos por categoria y la app te avisara cuando te acerques al limite.',
        'Miau! Un presupuesto no es una restriccion, es un plan. Te da libertad para gastar sin culpa dentro de tus limites.',
        'Tip de Cashito: Empieza con las categorias donde mas gastas. Si comes mucho afuera, pon un limite a Alimentacion.',
      ]);
    }

    // Metas
    if (_matchesAny(lower, ['meta', 'metas', 'objetivo', 'objetivos', 'goal'])) {
      return _randomFrom([
        'Las metas financieras son suenos con fecha! Crea una meta en la app, ponle un monto y ve tu progreso cada dia.',
        'Miau! Mi meta es tener atun ilimitado. Cual es la tuya? Unas vacaciones? Un auto? Ponlo en la app!',
        'Tip: Divide metas grandes en pequenas. Ahorrar S/12,000 suena dificil, pero S/1,000 al mes es mas alcanzable.',
      ]);
    }

    // Deudas
    if (_matchesAny(lower, ['deuda', 'deudas', 'debo', 'prestamo', 'prestamos', 'tarjeta credito'])) {
      return _randomFrom([
        'Las deudas son como bolas de pelo: hay que sacarlas lo antes posible! Prioriza pagar las de mayor interes primero.',
        'Miau! Si tienes varias deudas, prueba el metodo avalancha (pagar la de mayor interes) o bola de nieve (la mas pequena primero).',
        'Tip de Cashito: Evita pagar solo el minimo de la tarjeta. Los intereses se comen tu dinero como yo me como el atun.',
        'Antes de endeudarte, preguntate: puedo esperar y ahorrar para esto? Las deudas de consumo son las mas peligrosas.',
      ]);
    }

    // Ingresos
    if (_matchesAny(lower, ['ingreso', 'ingresos', 'sueldo', 'salario', 'ganar', 'dinero extra'])) {
      return _randomFrom([
        'Miau! Diversificar ingresos es importante. Tienes algun hobby que puedas monetizar?',
        'Registra todos tus ingresos en la app, incluso los pequenos. Asi tendras el panorama completo de tu situacion.',
        'Tip: Si recibes un aumento o bono, ahorra al menos la mitad antes de acostumbrarte a gastarlo.',
      ]);
    }

    // Yape / transferencias
    if (_matchesAny(lower, ['yape', 'plin', 'transferencia', 'transferir'])) {
      return _randomFrom([
        'Miau! Activa la deteccion automatica en Mas opciones y registrare tus Yapes automaticamente!',
        'Las transferencias digitales son super practicas, pero tambien hacen que gastemos mas facil. Pon limites!',
        'Tip: Revisa tu historial de Yape en la app. A veces gastamos sin darnos cuenta en pagos pequenos.',
      ]);
    }

    // Emergencias
    if (_matchesAny(lower, ['emergencia', 'emergencias', 'fondo emergencia', 'imprevisto'])) {
      return _randomFrom([
        'Un fondo de emergencia es como tener 9 vidas! Intenta ahorrar 3-6 meses de gastos para imprevistos.',
        'Miau! Los imprevistos pasan. Sin fondo de emergencia, terminas endeudandote. Empieza con S/1,000 como meta inicial.',
        'Tip de Cashito: El fondo de emergencia no es para ofertas ni viajes. Es solo para emergencias reales!',
      ]);
    }

    // Inversiones
    if (_matchesAny(lower, ['invertir', 'inversion', 'inversiones', 'acciones', 'fondos mutuos'])) {
      return _randomFrom([
        'Miau! Antes de invertir, asegurate de tener tu fondo de emergencia y cero deudas de alto interes.',
        'Invertir es hacer que tu dinero trabaje para ti mientras duermes la siesta. Pero primero, educate!',
        'Tip: Empieza con fondos mutuos o depositos a plazo si eres principiante. No inviertas en lo que no entiendes.',
      ]);
    }

    // Comida / restaurantes
    if (_matchesAny(lower, ['comida', 'restaurante', 'delivery', 'rappi', 'pedidos ya', 'comer afuera'])) {
      return _randomFrom([
        'El delivery es mi enemigo! Cocinar en casa puede ahorrarte hasta 70% comparado con pedir comida.',
        'Miau! Pon un presupuesto para Alimentacion y Restaurantes por separado. Asi controlas mejor.',
        'Tip de Cashito: Lleva almuerzo al trabajo. Tu billetera (y tu barriga) te lo agradeceran.',
      ]);
    }

    // Suscripciones
    if (_matchesAny(lower, ['suscripcion', 'suscripciones', 'netflix', 'spotify', 'streaming'])) {
      return _randomFrom([
        'Las suscripciones son gastos ninja: pequenos pero constantes! Revisa cuales realmente usas.',
        'Miau! Haz una lista de todas tus suscripciones. Seguro hay alguna que olvidaste y sigues pagando.',
        'Tip: Comparte cuentas familiares cuando sea posible. Netflix, Spotify, YouTube... todo suma!',
      ]);
    }

    // Ayuda con la app
    if (_matchesAny(lower, ['como', 'ayuda', 'funciona', 'usar', 'donde', 'puedo'])) {
      return _randomFrom([
        'Miau! Puedo ayudarte! Para agregar transacciones usa el boton + abajo. Para ver reportes ve a la seccion Reportes.',
        'La app tiene: Inicio (resumen), Transacciones (historial), Reportes (graficos) y Mas (configuracion).',
        'Tip: Activa la deteccion automatica en Mas opciones > Deteccion automatica para registrar Yapes automaticamente!',
        'Para escanear boletas, ve a agregar transaccion y toca el icono de camara o documento.',
      ]);
    }

    // Quien eres
    if (_matchesAny(lower, ['quien eres', 'que eres', 'tu nombre', 'como te llamas', 'cashito'])) {
      return _randomFrom([
        'Soy Cashito! Tu gatito financiero personal. Cuido tu alcancia y te doy consejos para que tu dinero crezca.',
        'Miau! Me llamo Cashito y soy el guardian de tus finanzas. Mi mision es ayudarte a gastar menos y ahorrar mas!',
        '*se estira* Soy Cashito, un gatito muy listo en temas de dinero. Preguntame lo que quieras!',
      ]);
    }

    // Estado de animo / motivacion
    if (_matchesAny(lower, ['triste', 'mal', 'preocupado', 'estres', 'ansiedad', 'dinero me estresa'])) {
      return _randomFrom([
        '*te da un cabezazo carinyoso* Miau... entiendo que el dinero puede ser estresante. Pero paso a paso se logra!',
        'No te preocupes! El primer paso es saber donde estas. Ya estas usando la app, eso es un gran avance!',
        'Respiremos juntos. Las finanzas se arreglan con paciencia y constancia. Estoy aqui para ayudarte.',
      ]);
    }

    // Respuestas por defecto (cuando no entiende)
    return _randomFrom([
      'Miau? No estoy seguro de entender. Puedes preguntarme sobre ahorro, gastos, presupuestos o metas!',
      '*ladea la cabeza* Hmm, no capte eso. Intenta preguntarme sobre como ahorrar o controlar tus gastos.',
      'Purr... mi cerebro gatuno no proceso eso. Preguntame sobre finanzas personales y te ayudo!',
      'Miau! Soy bueno en temas de dinero. Preguntame sobre ahorro, deudas, presupuestos o como usar la app.',
    ]);
  }

  static bool _matchesAny(String text, List<String> keywords) {
    return keywords.any((kw) => text.contains(kw));
  }

  static String _randomFrom(List<String> options) {
    final index = (_random + DateTime.now().microsecond) % options.length;
    return options[index];
  }

  /// Mensajes iniciales de bienvenida
  static List<String> getWelcomeMessages() {
    return [
      'Miau! Hola, soy Cashito, tu asistente financiero gatuno!',
      'Puedes preguntarme sobre ahorro, gastos, presupuestos, metas, deudas y mas.',
      'Tambien puedo darte tips para mejorar tus finanzas. En que te ayudo hoy?',
    ];
  }
}
