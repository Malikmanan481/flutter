import 'package:equatable/equatable.dart';

abstract class WindowState extends Equatable {
  const WindowState();

  @override
  List<Object?> get props => [];
}

class PositionChangedState extends WindowState {
  final double? offsetY, offsetX;

  PositionChangedState({this.offsetX, this.offsetY});

  @override
  List<Object?> get props => [offsetX, offsetY];
}

class NoEventState extends WindowState {}

// ==========================================
// TRACCAR API BACKEND INTEGRATION STATES
// ==========================================

/// Emitted when live position data is received from Traccar `/api/positions`
class TraccarDataLoadedState extends WindowState {
  final Map<String, String> formattedData;
  final Map<String, dynamic>? rawPositionJson;

  const TraccarDataLoadedState({
    required this.formattedData,
    this.rawPositionJson,
  });

  @override
  List<Object?> get props => [formattedData, rawPositionJson];
}

/// Emitted when fetching data from Traccar backend API
class TraccarLoadingState extends WindowState {}

/// Emitted if Traccar API request fails
class TraccarErrorState extends WindowState {
  final String errorMessage;

  const TraccarErrorState(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
