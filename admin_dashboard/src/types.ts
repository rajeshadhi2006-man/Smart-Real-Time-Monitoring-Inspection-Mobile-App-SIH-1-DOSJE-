export interface OfficerLocation {
  id: string | number;
  user_id: string;
  name: string;
  role: string;
  latitude: number;
  longitude: number;
  accuracy: number;
  altitude: number;
  speed: number;
  heading: number;
  created_at: string;
  is_online: boolean;
  is_inside: boolean;
  distance_from_perimeter: number;
  tracking_session_id?: string;
}

export interface GeofenceZone {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
  radius_meters: number;
  description?: string;
}

export interface AssignmentSubmission {
  evidence_id: string;
  assignment_id: string;
  user_id: string;
  officer_name?: string;
  assignment_title?: string;
  image_url: string;
  latitude: number;
  longitude: number;
  target_latitude?: number;
  target_longitude?: number;
  geohash: string;
  target_geohash?: string;
  allowed_radius_meters?: number;
  gps_accuracy: number;
  captured_at: string;
  server_verified_at?: string;
  location_verified: boolean;
  verification_reason?: string;
  submission_status: string;
  distance_meters?: number;
}
