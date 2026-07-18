import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/abstinence_tracker.dart';
import '../../data/models/blocked_app.dart';
import '../../data/models/blocked_domain.dart';
import '../../data/repositories/addiction_support_repository.dart';

// ─── Repository Provider ──────────────────────────────────────

final addictionSupportRepositoryProvider = Provider<AddictionSupportRepository>((ref) {
  return AddictionSupportRepository(Supabase.instance.client);
});

// ─── Abstinence Tracker ───────────────────────────────────────

final abstinenceTrackerProvider = FutureProvider<AbstinenceTracker?>((ref) async {
  final repo = ref.watch(addictionSupportRepositoryProvider);
  return repo.getTracker();
});

class AbstinenceTrackerNotifier extends StateNotifier<AsyncValue<AbstinenceTracker?>> {
  final AddictionSupportRepository _repo;

  AbstinenceTrackerNotifier(this._repo) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final tracker = await _repo.getTracker();
      state = AsyncValue.data(tracker);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<void> startTracker(double dailyBetAverage) async {
    try {
      final tracker = await _repo.createTracker(dailyBetAverage: dailyBetAverage);
      state = AsyncValue.data(tracker);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> resetStreak() async {
    final current = state.valueOrNull;
    if (current == null) return;

    try {
      final updated = await _repo.resetStreak(current);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateDailyAverage(double amount) async {
    final current = state.valueOrNull;
    if (current == null) return;

    try {
      final updated = await _repo.updateTracker(
        current.copyWith(dailyBetAverage: amount),
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> checkIn() async {
    final current = state.valueOrNull;
    if (current == null) return;

    try {
      await _repo.incrementStreak(current);
      await _load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final abstinenceTrackerNotifierProvider =
    StateNotifierProvider<AbstinenceTrackerNotifier, AsyncValue<AbstinenceTracker?>>((ref) {
  final repo = ref.watch(addictionSupportRepositoryProvider);
  return AbstinenceTrackerNotifier(repo);
});

// ─── Blocked Apps ─────────────────────────────────────────────

final blockedAppsProvider = FutureProvider<List<BlockedApp>>((ref) async {
  final repo = ref.watch(addictionSupportRepositoryProvider);
  return repo.getBlockedApps();
});

class BlockedAppsNotifier extends StateNotifier<AsyncValue<List<BlockedApp>>> {
  final AddictionSupportRepository _repo;

  BlockedAppsNotifier(this._repo) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final apps = await _repo.getBlockedApps();
      state = AsyncValue.data(apps);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<void> addApp(String name, String packageName) async {
    try {
      await _repo.addBlockedApp(appName: name, packageName: packageName);
      await _load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeApp(String id) async {
    try {
      await _repo.removeBlockedApp(id);
      await _load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final blockedAppsNotifierProvider =
    StateNotifierProvider<BlockedAppsNotifier, AsyncValue<List<BlockedApp>>>((ref) {
  final repo = ref.watch(addictionSupportRepositoryProvider);
  return BlockedAppsNotifier(repo);
});

// ─── Blocked Domains ──────────────────────────────────────────

final blockedDomainsProvider = FutureProvider<List<BlockedDomain>>((ref) async {
  final repo = ref.watch(addictionSupportRepositoryProvider);
  return repo.getBlockedDomains();
});

class BlockedDomainsNotifier extends StateNotifier<AsyncValue<List<BlockedDomain>>> {
  final AddictionSupportRepository _repo;

  BlockedDomainsNotifier(this._repo) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final domains = await _repo.getBlockedDomains();
      state = AsyncValue.data(domains);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<void> addDomain(String url) async {
    try {
      await _repo.addBlockedDomain(url);
      await _load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeDomain(String id) async {
    try {
      await _repo.removeBlockedDomain(id);
      await _load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final blockedDomainsNotifierProvider =
    StateNotifierProvider<BlockedDomainsNotifier, AsyncValue<List<BlockedDomain>>>((ref) {
  final repo = ref.watch(addictionSupportRepositoryProvider);
  return BlockedDomainsNotifier(repo);
});

// ─── Support Resources ────────────────────────────────────────

class SupportResource {
  final String name;
  final String description;
  final String phone;
  final String? website;
  final String icon;

  const SupportResource({
    required this.name,
    required this.description,
    required this.phone,
    this.website,
    this.icon = '📞',
  });
}

final supportResourcesProvider = Provider<List<SupportResource>>((ref) {
  return const [
    SupportResource(
      name: 'Linea 113 - MINSA',
      description: 'Linea de salud mental del Ministerio de Salud',
      phone: '113',
      website: 'https://www.gob.pe/minsa',
      icon: '🏥',
    ),
    SupportResource(
      name: 'CEDRO',
      description: 'Centro de informacion y educacion para la prevencion del abuso de drogas',
      phone: '(01) 447-5837',
      website: 'https://www.cedro.org.pe',
      icon: '🌿',
    ),
    SupportResource(
      name: 'Jugadores Anonimos Peru',
      description: 'Grupos de apoyo para personas con problemas de juego',
      phone: '(01) 431-4353',
      website: 'https://jugadoresanonimos.org',
      icon: '🤝',
    ),
    SupportResource(
      name: 'INSM Honorio Delgado',
      description: 'Instituto Nacional de Salud Mental',
      phone: '(01) 614-9200',
      website: 'https://www.insm.gob.pe',
      icon: '🧠',
    ),
    SupportResource(
      name: 'Linea 100',
      description: 'Servicio gratuito de orientacion (MIMP)',
      phone: '100',
      icon: '📱',
    ),
  ];
});

// ─── Known Betting Apps/Domains ───────────────────────────────

class KnownBettingApp {
  final String name;
  final String packageName;
  final String icon;

  const KnownBettingApp({
    required this.name,
    required this.packageName,
    this.icon = '🎰',
  });
}

final knownBettingAppsProvider = Provider<List<KnownBettingApp>>((ref) {
  return const [
    KnownBettingApp(name: 'Betsson', packageName: 'com.betsson.android', icon: '🎲'),
    KnownBettingApp(name: 'Bet365', packageName: 'com.bet365.app', icon: '⚽'),
    KnownBettingApp(name: 'Betway', packageName: 'com.betway.app', icon: '🏀'),
    KnownBettingApp(name: 'Inkabet', packageName: 'com.inkabet.app', icon: '🎯'),
    KnownBettingApp(name: 'Doradobet', packageName: 'com.doradobet.app', icon: '🃏'),
    KnownBettingApp(name: 'Apuesta Total', packageName: 'com.apuestatotal.app', icon: '🏆'),
    KnownBettingApp(name: '1xBet', packageName: 'com.xbet.app', icon: '🎰'),
    KnownBettingApp(name: 'Codere', packageName: 'com.codere.app', icon: '🎲'),
    KnownBettingApp(name: 'Te Apuesto', packageName: 'com.teapuesto.app', icon: '🏇'),
    KnownBettingApp(name: 'Solbet', packageName: 'com.solbet.app', icon: '☀️'),
  ];
});

final knownBettingDomainsProvider = Provider<List<String>>((ref) {
  return const [
    'bet365.com',
    'betsson.com',
    'betway.com',
    'inkabet.pe',
    'doradobet.com',
    'apuestatotal.com',
    '1xbet.com',
    'codere.pe',
    'teapuesto.com.pe',
    'solbet.pe',
    'casino.com',
    'pokerstars.com',
    'bwin.com',
    'williamhill.com',
  ];
});
