import 'package:flutter/foundation.dart';
import '../models/status_model.dart';
import '../services/storage_access_service.dart';
import 'settings_provider.dart';

class StatusProvider with ChangeNotifier {
  final SettingsProvider _settingsProvider;
  List<StatusModel> _statuses = [];
  bool _isLoading = false;
  String? _error;

  StatusProvider(this._settingsProvider);

  List<StatusModel> get statuses {
    return _statuses.where((status) {
      if (status.appSource == 'WhatsApp') {
        return _settingsProvider.whatsappEnabled;
      } else if (status.appSource == 'WhatsApp Business') {
        return _settingsProvider.whatsappBusinessEnabled;
      }
      return false;
    }).toList();
  }

  List<StatusModel> getStatusesByType(String type) {
    return statuses.where((status) => status.mediaType == type).toList();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadStatuses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _statuses = await StorageAccessService.getAllStatuses();
      if (_statuses.isEmpty) {
        _error =
            'No statuses found. Try opening WhatsApp and viewing some statuses.';
      }
    } catch (e) {
      _error = 'Error loading statuses: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveStatus(StatusModel status) async {
    try {
      final success = await StorageAccessService.saveStatus(status);
      if (success) {
        final index = _statuses.indexWhere((s) => s.path == status.path);
        if (index != -1) {
          _statuses[index].isFavorite = true;
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      debugPrint('Error saving status: $e');
      return false;
    }
  }

  void refresh() {
    loadStatuses();
  }
}
