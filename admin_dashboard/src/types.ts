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
