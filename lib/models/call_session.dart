// ignore_for_file: constant_identifier_names

enum CallState {
  CALLING,
  RINGING,
  ACCEPTED,
  CONNECTING,
  CONNECTED,
  REJECTED,
  MISSED,
  ENDED,
  FAILED,
}

class CallSession {
  final String id;
  final String personId;
  final String personName;
  final CallState state;
  final String? sdpOffer;
  final String? sdpAnswer;
  final DateTime createdAt;

  const CallSession({
    required this.id,
    required this.personId,
    required this.personName,
    required this.state,
    this.sdpOffer,
    this.sdpAnswer,
    required this.createdAt,
  });

  factory CallSession.fromJson(Map<String, dynamic> json) {
    CallState parsedState = CallState.CALLING;
    final stateStr = json['state']?.toString().toUpperCase();
    for (var val in CallState.values) {
      if (val.name == stateStr) {
        parsedState = val;
        break;
      }
    }

    return CallSession(
      id: json['id']?.toString() ?? '',
      personId: json['person_id']?.toString() ?? '',
      personName: json['person_name'] ?? 'Target User',
      state: parsedState,
      sdpOffer: json['sdp_offer'],
      sdpAnswer: json['sdp_answer'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'person_id': personId,
      'person_name': personName,
      'state': state.name,
      'sdp_offer': sdpOffer,
      'sdp_answer': sdpAnswer,
      'created_at': createdAt.toIso8601String(),
    };
  }

  CallSession copyWith({
    CallState? state,
    String? sdpOffer,
    String? sdpAnswer,
  }) {
    return CallSession(
      id: id,
      personId: personId,
      personName: personName,
      state: state ?? this.state,
      sdpOffer: sdpOffer ?? this.sdpOffer,
      sdpAnswer: sdpAnswer ?? this.sdpAnswer,
      createdAt: createdAt,
    );
  }
}
