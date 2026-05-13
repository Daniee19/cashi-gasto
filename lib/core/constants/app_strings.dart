class AppStrings {
  AppStrings._();

  // App Info
  static const String appName = 'Cashi Gasto';
  static const String mascotName = 'Cashito';

  // Auth
  static const String login = 'Iniciar Sesion';
  static const String register = 'Registrarse';
  static const String logout = 'Cerrar Sesion';
  static const String email = 'Correo electronico';
  static const String password = 'Contrasena';
  static const String confirmPassword = 'Confirmar contrasena';
  static const String fullName = 'Nombre completo';
  static const String forgotPassword = 'Olvide mi contrasena';
  static const String dontHaveAccount = 'No tienes cuenta?';
  static const String alreadyHaveAccount = 'Ya tienes cuenta?';
  static const String loginWithGoogle = 'Continuar con Google';

  // Onboarding
  static const String welcome = 'Bienvenido a Cashi Gasto';
  static const String selectProfile = 'Selecciona tu perfil';
  static const String youthProfile = 'Joven';
  static const String youthProfileDesc = 'Quiero aprender a manejar mis finanzas';
  static const String businessProfile = 'Negocio';
  static const String businessProfileDesc = 'Quiero controlar los gastos de mi empresa';
  static const String supportProfile = 'Soporte';
  static const String supportProfileDesc = 'Necesito ayuda con la adiccion al juego';

  // Navigation
  static const String home = 'Inicio';
  static const String transactions = 'Transacciones';
  static const String budgets = 'Presupuestos';
  static const String goals = 'Metas';
  static const String more = 'Mas';

  // Transactions
  static const String income = 'Ingreso';
  static const String expense = 'Gasto';
  static const String transfer = 'Transferencia';
  static const String addTransaction = 'Agregar transaccion';
  static const String amount = 'Monto';
  static const String category = 'Categoria';
  static const String date = 'Fecha';
  static const String note = 'Nota';
  static const String fund = 'Cuenta';

  // Categories
  static const String food = 'Alimentacion';
  static const String transport = 'Transporte';
  static const String entertainment = 'Entretenimiento';
  static const String shopping = 'Compras';
  static const String health = 'Salud';
  static const String education = 'Educacion';
  static const String bills = 'Servicios';
  static const String salary = 'Salario';
  static const String investment = 'Inversiones';
  static const String other = 'Otros';

  // Funds
  static const String cash = 'Efectivo';
  static const String bank = 'Banco';
  static const String savings = 'Ahorros';
  static const String balance = 'Balance';

  // Budgets
  static const String createBudget = 'Crear presupuesto';
  static const String budgetedAmount = 'Monto presupuestado';
  static const String spent = 'Gastado';
  static const String remaining = 'Restante';
  static const String period = 'Periodo';
  static const String weekly = 'Semanal';
  static const String monthly = 'Mensual';
  static const String yearly = 'Anual';

  // Goals
  static const String createGoal = 'Crear meta';
  static const String targetAmount = 'Monto objetivo';
  static const String currentAmount = 'Monto actual';
  static const String deadline = 'Fecha limite';
  static const String progress = 'Progreso';

  // Loans
  static const String loans = 'Prestamos';
  static const String lent = 'Prestado';
  static const String borrowed = 'Pedido prestado';
  static const String pending = 'Pendiente';
  static const String paid = 'Pagado';

  // Chatbot
  static const String askCashito = 'Preguntale a Cashito';
  static const String chatbotHint = 'Escribe tu pregunta...';
  static const String dailyLimitReached = 'Has alcanzado tu limite diario de mensajes';

  // Addiction Support
  static const String abstinenceTracker = 'Rastreador de abstinencia';
  static const String daysClean = 'dias sin apostar';
  static const String currentStreak = 'Racha actual';
  static const String longestStreak = 'Mejor racha';
  static const String moneySaved = 'Dinero ahorrado';
  static const String blockedApps = 'Apps bloqueadas';
  static const String supportResources = 'Recursos de apoyo';
  static const String resetStreak = 'Reiniciar racha';
  static const String keepGoing = 'Sigue asi!';

  // Common
  static const String save = 'Guardar';
  static const String cancel = 'Cancelar';
  static const String delete = 'Eliminar';
  static const String edit = 'Editar';
  static const String confirm = 'Confirmar';
  static const String search = 'Buscar';
  static const String filter = 'Filtrar';
  static const String noData = 'Sin datos';
  static const String loading = 'Cargando...';
  static const String error = 'Error';
  static const String success = 'Exito';
  static const String settings = 'Configuracion';
  static const String profile = 'Perfil';
  static const String reports = 'Reportes';

  // Errors
  static const String requiredField = 'Este campo es requerido';
  static const String invalidEmail = 'Correo electronico invalido';
  static const String passwordTooShort = 'La contrasena debe tener al menos 6 caracteres';
  static const String passwordsDoNotMatch = 'Las contrasenas no coinciden';
  static const String somethingWentWrong = 'Algo salio mal';
  static const String networkError = 'Error de conexion';

  // Cashito Messages
  static const List<String> cashitoGreetings = [
    'Hola! Soy Cashito, tu asistente financiero',
    'Como puedo ayudarte hoy con tus finanzas?',
    'Recuerda: cada peso cuenta!',
    'Vamos a hacer crecer tus ahorros juntos!',
  ];

  static const List<String> cashitoMotivational = [
    'Excelente trabajo! Sigue asi!',
    'Cada pequeno ahorro cuenta!',
    'Tu futuro financiero se construye hoy!',
    'Eres increible manejando tu dinero!',
    'Un paso a la vez hacia tus metas!',
  ];
}
