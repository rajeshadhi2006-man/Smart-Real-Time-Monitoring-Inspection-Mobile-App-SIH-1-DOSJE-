import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/app_config.dart';
import '../models/tracking_session.dart';
import '../models/user_location.dart';

/// Backend service responsible for persisting location updates, sessions,
/// and synchronizing buffered offline records to Supabase.
class SupabaseService {
  static SupabaseClient? _client;

  /// Initializes Supabase client if not already initialized
  static SupabaseClient get client {
    if (_client != null) return _client!;
    try {
      _client = Supabase.instance.client;
    } catch (_) {
      // In case Supabase has not been initialized via Supabase.initialize() in main
      developer.log('Supabase instance client accessed prior to initialization or mock mode active.');
    }
    return _client ?? SupabaseClient(AppConfig.supabaseUrl, AppConfig.supabaseAnonKey);
  }

  /// Inserts a live location record into Supabase PostgreSQL `location_updates`
  Future<bool> sendLocationUpdate(UserLocation location) async {
    try {
      final payload = location.toSupabaseMap();
      await client.from('location_updates').insert(payload);
      developer.log('Live location successfully pushed to Supabase: ${location.latitude}, ${location.longitude}');
      return true;
    } catch (e, st) {
      developer.log('Supabase real-time write failed: $e', error: e, stackTrace: st);
      return false;
    }
  }

  /// Synchronizes a batch of offline-queued updates
  Future<int> syncOfflineBatch(List<UserLocation> batch) async {
    if (batch.isEmpty) return 0;
    try {
      final payload = batch.map((loc) => loc.toSupabaseMap()).toList();
      await client.from('location_updates').insert(payload);
      developer.log('Successfully synced ${batch.length} offline records to Supabase');
      return batch.length;
    } catch (e) {
      developer.log('Failed to sync offline batch to Supabase: $e');
      return 0;
    }
  }

  /// Registers a new active tracking session
  Future<bool> startTrackingSession(TrackingSession session) async {
    try {
      await client.from('tracking_sessions').upsert(session.toJson());
      developer.log('Tracking session ${session.id} registered in Supabase');
      return true;
    } catch (e) {
      developer.log('Failed to start tracking session in Supabase: $e');
      return false;
    }
  }

  /// Concludes an active tracking session
  Future<bool> stopTrackingSession(String sessionId) async {
    try {
      await client.from('tracking_sessions').update({
        'is_active': false,
        'ended_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', sessionId);
      developer.log('Tracking session $sessionId concluded in Supabase');
      return true;
    } catch (e) {
      developer.log('Failed to stop tracking session in Supabase: $e');
      return false;
    }
  }
}
