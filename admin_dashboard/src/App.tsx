import { useState, useEffect, useMemo } from 'react';
import { Header } from './components/Header';
import { UserRoster } from './components/UserRoster';
import { MapView } from './components/MapView';
import { EnrollInspectionModal } from './components/EnrollInspectionModal';
import { OfficerLocation, GeofenceZone } from './types';
import { supabase } from './supabase';
import { Sliders, MapPin, Check, RefreshCw } from 'lucide-react';

// Default initial geofence coordinates (configurable dynamically by admin)
const initialGeofence: GeofenceZone = {
  id: 'GEOFENCE-ACTIVE',
  name: 'Official Audit Target Zone',
  latitude: 11.016844,
  longitude: 76.955832,
  radius_meters: 500.0,
  description: 'Dynamic inspection perimeter configured for field verification.',
};

// Haversine calculation to determine geodesic distance
function calculateDistanceInMeters(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371000; // meters
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

export function App() {
  // ZERO hardcoded/predefined officers - purely populated from real-time Supabase telemetry
  const [officers, setOfficers] = useState<OfficerLocation[]>([]);
  const [selectedOfficer, setSelectedOfficer] = useState<OfficerLocation | null>(null);
  const [isRealtimeConnected, setIsRealtimeConnected] = useState(false);
  const [isLoadingInitial, setIsLoadingInitial] = useState(true);
  const [geofence, setGeofence] = useState<GeofenceZone>(initialGeofence);
  const [hasCustomGeofence, setHasCustomGeofence] = useState(false);
  const [isConfiguringGeofence, setIsConfiguringGeofence] = useState(false);
  const [isEnrollModalOpen, setIsEnrollModalOpen] = useState(false);

  // Form state for dynamic geofence configuration
  const [geoForm, setGeoForm] = useState({
    name: geofence.name,
    latitude: geofence.latitude.toString(),
    longitude: geofence.longitude.toString(),
    radius_meters: geofence.radius_meters.toString(),
  });

  // Helper to re-evaluate geofence containment for all active officers
  const evaluateOfficerGeofence = (
    lat: number,
    lon: number,
    targetGeofence: GeofenceZone
  ) => {
    const centerDistance = calculateDistanceInMeters(
      lat,
      lon,
      targetGeofence.latitude,
      targetGeofence.longitude
    );
    const isInside = centerDistance <= targetGeofence.radius_meters;
    const perimeterDistance = isInside ? 0 : centerDistance - targetGeofence.radius_meters;
    return { isInside, perimeterDistance };
  };

  // Fetch real latest location updates from Supabase
  const fetchRecentLocations = async () => {
    try {
      setIsLoadingInitial(true);
      const { data, error } = await supabase
        .from('location_updates')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(100);

      if (error) {
        console.warn('Supabase fetch error or table empty:', error.message);
        return;
      }

      if (data && data.length > 0) {
        // Group by user_id to get only the most recent coordinate per officer
        const latestByUser = new Map<string, any>();
        for (const row of data) {
          if (!latestByUser.has(row.user_id)) {
            latestByUser.set(row.user_id, row);
          }
        }

        const realOfficers: OfficerLocation[] = Array.from(latestByUser.values()).map(
          (row) => {
            const { isInside, perimeterDistance } = evaluateOfficerGeofence(
              row.latitude,
              row.longitude,
              geofence
            );
            return {
              id: row.id,
              user_id: row.user_id,
              name: row.user_id,
              role: 'Field Inspector',
              latitude: Number(row.latitude),
              longitude: Number(row.longitude),
              accuracy: Number(row.accuracy || 10),
              altitude: Number(row.altitude || 0),
              speed: Number(row.speed || 0),
              heading: Number(row.heading || 0),
              created_at: row.created_at,
              is_online: Date.now() - new Date(row.created_at).getTime() < 300000, // active within last 5m
              is_inside: isInside,
              distance_from_perimeter: perimeterDistance,
            };
          }
        );

        if (!hasCustomGeofence && realOfficers.length > 0) {
          const first = realOfficers[0];
          const autoGeo: GeofenceZone = {
            id: 'GEOFENCE-LIVE',
            name: `Live Field Inspection Zone`,
            latitude: first.latitude,
            longitude: first.longitude,
            radius_meters: 500,
            description: 'Auto-aligned to live officer GPS telemetry',
          };
          setGeofence(autoGeo);
          setGeoForm({
            name: autoGeo.name,
            latitude: autoGeo.latitude.toString(),
            longitude: autoGeo.longitude.toString(),
            radius_meters: autoGeo.radius_meters.toString(),
          });
        }

        setOfficers(realOfficers);
      }
    } catch (err) {
      console.error('Error fetching initial locations:', err);
    } finally {
      setIsLoadingInitial(false);
    }
  };

  useEffect(() => {
    fetchRecentLocations();

    // Subscribe to Supabase Realtime channel for live INSERT events on location_updates
    const channel = supabase
      .channel('public:location_updates')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'location_updates' },
        (payload) => {
          const update = payload.new as any;
          if (!update || update.latitude == null || update.longitude == null) return;

          const lat = Number(update.latitude);
          const lon = Number(update.longitude);

          if (!hasCustomGeofence) {
            const autoGeo: GeofenceZone = {
              id: 'GEOFENCE-LIVE',
              name: `Live Inspection Zone`,
              latitude: lat,
              longitude: lon,
              radius_meters: 500,
              description: 'Auto-aligned to live officer GPS telemetry',
            };
            setGeofence(autoGeo);
            setGeoForm({
              name: autoGeo.name,
              latitude: autoGeo.latitude.toString(),
              longitude: autoGeo.longitude.toString(),
              radius_meters: autoGeo.radius_meters.toString(),
            });
          }

          const { isInside, perimeterDistance } = evaluateOfficerGeofence(lat, lon, geofence);

          setOfficers((prev) => {
            const existingIndex = prev.findIndex((o) => o.user_id === update.user_id);
            const updatedOfficer: OfficerLocation = {
              id: update.id || Date.now(),
              user_id: update.user_id,
              name: update.user_id,
              role: 'Field Inspector',
              latitude: lat,
              longitude: lon,
              accuracy: Number(update.accuracy || 10),
              altitude: Number(update.altitude || 0),
              speed: Number(update.speed || 0),
              heading: Number(update.heading || 0),
              created_at: update.created_at || new Date().toISOString(),
              is_online: true,
              is_inside: isInside,
              distance_from_perimeter: perimeterDistance,
            };

            if (existingIndex !== -1) {
              const clone = [...prev];
              clone[existingIndex] = updatedOfficer;
              return clone;
            } else {
              return [updatedOfficer, ...prev];
            }
          });
        }
      )
      .subscribe((status) => {
        setIsRealtimeConnected(status === 'SUBSCRIBED');
      });

    return () => {
      supabase.removeChannel(channel);
    };
  }, [geofence]);

  // Handle Geofence form submission
  const handleSaveGeofence = (e: React.FormEvent) => {
    e.preventDefault();
    const newLat = parseFloat(geoForm.latitude);
    const newLon = parseFloat(geoForm.longitude);
    const newRadius = parseFloat(geoForm.radius_meters);

    if (isNaN(newLat) || isNaN(newLon) || isNaN(newRadius)) {
      alert('Please enter valid numeric latitude, longitude, and radius values.');
      return;
    }

    const updatedGeofence: GeofenceZone = {
      ...geofence,
      name: geoForm.name || 'Custom Target Zone',
      latitude: newLat,
      longitude: newLon,
      radius_meters: newRadius,
    };

    setGeofence(updatedGeofence);
    setHasCustomGeofence(true);

    // Re-evaluate existing officers against updated geofence
    setOfficers((prev) =>
      prev.map((off) => {
        const { isInside, perimeterDistance } = evaluateOfficerGeofence(
          off.latitude,
          off.longitude,
          updatedGeofence
        );
        return {
          ...off,
          is_inside: isInside,
          distance_from_perimeter: perimeterDistance,
        };
      })
    );

    setIsConfiguringGeofence(false);
  };

  const alignGeofenceToOfficer = (officer: OfficerLocation) => {
    const updated: GeofenceZone = {
      ...geofence,
      name: `${officer.name} Site`,
      latitude: officer.latitude,
      longitude: officer.longitude,
      radius_meters: 500,
    };
    setGeofence(updated);
    setHasCustomGeofence(true);
    setGeoForm({
      name: updated.name,
      latitude: updated.latitude.toString(),
      longitude: updated.longitude.toString(),
      radius_meters: updated.radius_meters.toString(),
    });
    setOfficers((prev) =>
      prev.map((off) => {
        const { isInside, perimeterDistance } = evaluateOfficerGeofence(
          off.latitude,
          off.longitude,
          updated
        );
        return {
          ...off,
          is_inside: isInside,
          distance_from_perimeter: perimeterDistance,
        };
      })
    );
  };

  const activeCount = useMemo(() => officers.filter((o) => o.is_online).length, [officers]);
  const insideCount = useMemo(() => officers.filter((o) => o.is_inside).length, [officers]);
  const outsideCount = useMemo(() => officers.filter((o) => !o.is_inside).length, [officers]);

  return (
    <div className="flex flex-col h-screen w-screen overflow-hidden bg-slate-100">
      {/* Government Monitoring Header */}
      <Header
        activeCount={activeCount}
        insideCount={insideCount}
        outsideCount={outsideCount}
        isRealtimeConnected={isRealtimeConnected}
        onOpenEnrollModal={() => setIsEnrollModalOpen(true)}
      />

      {/* Geofence Configuration Bar */}
      <div className="bg-slate-800 text-slate-200 px-4 py-2 flex items-center justify-between border-b border-slate-700 text-xs">
        <div className="flex items-center space-x-3">
          <MapPin className="w-4 h-4 text-teal-400" />
          <span>
            <strong className="text-white">Active Geofence:</strong> {geofence.name} (
            {geofence.latitude.toFixed(5)}, {geofence.longitude.toFixed(5)}) • Radius:{' '}
            <strong>{geofence.radius_meters}m</strong>
          </span>
        </div>
        <div className="flex items-center space-x-2">
          <button
            onClick={fetchRecentLocations}
            className="flex items-center space-x-1 bg-slate-700 hover:bg-slate-600 px-2.5 py-1 rounded text-slate-200 transition"
            title="Refresh latest telemetry"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${isLoadingInitial ? 'animate-spin' : ''}`} />
            <span>Refresh</span>
          </button>
          <button
            onClick={() => setIsConfiguringGeofence(!isConfiguringGeofence)}
            className="flex items-center space-x-1 bg-blue-600 hover:bg-blue-500 text-white px-2.5 py-1 rounded font-semibold transition"
          >
            <Sliders className="w-3.5 h-3.5" />
            <span>{isConfiguringGeofence ? 'Close Editor' : 'Configure Geofence'}</span>
          </button>
        </div>
      </div>

      {/* Geofence Editor Modal / Accordion */}
      {isConfiguringGeofence && (
        <form
          onSubmit={handleSaveGeofence}
          className="bg-white border-b border-slate-200 p-4 shadow-md flex flex-wrap items-center gap-4 text-xs"
        >
          <div className="flex flex-col">
            <label className="font-semibold text-slate-700 mb-1">Target Name</label>
            <input
              type="text"
              value={geoForm.name}
              onChange={(e) => setGeoForm({ ...geoForm, name: e.target.value })}
              className="border border-slate-300 rounded px-2.5 py-1 text-slate-800 focus:ring-2 focus:ring-blue-500"
              placeholder="e.g. Coimbatore Rehabilitation Center"
            />
          </div>

          <div className="flex flex-col">
            <label className="font-semibold text-slate-700 mb-1">Center Latitude</label>
            <input
              type="text"
              value={geoForm.latitude}
              onChange={(e) => setGeoForm({ ...geoForm, latitude: e.target.value })}
              className="border border-slate-300 rounded px-2.5 py-1 text-slate-800 focus:ring-2 focus:ring-blue-500 w-32"
              placeholder="11.016844"
            />
          </div>

          <div className="flex flex-col">
            <label className="font-semibold text-slate-700 mb-1">Center Longitude</label>
            <input
              type="text"
              value={geoForm.longitude}
              onChange={(e) => setGeoForm({ ...geoForm, longitude: e.target.value })}
              className="border border-slate-300 rounded px-2.5 py-1 text-slate-800 focus:ring-2 focus:ring-blue-500 w-32"
              placeholder="76.955832"
            />
          </div>

          <div className="flex flex-col">
            <label className="font-semibold text-slate-700 mb-1">Radius (meters)</label>
            <input
              type="text"
              value={geoForm.radius_meters}
              onChange={(e) => setGeoForm({ ...geoForm, radius_meters: e.target.value })}
              className="border border-slate-300 rounded px-2.5 py-1 text-slate-800 focus:ring-2 focus:ring-blue-500 w-24"
              placeholder="500"
            />
          </div>

          <button
            type="submit"
            className="mt-4 flex items-center space-x-1 bg-emerald-600 hover:bg-emerald-500 text-white font-bold px-3 py-1.5 rounded transition"
          >
            <Check className="w-4 h-4" />
            <span>Apply Geofence</span>
          </button>
        </form>
      )}

      {/* Main Content Area: Roster on Left, OpenStreetMap on Right */}
      <div className="flex flex-1 overflow-hidden">
        <UserRoster
          officers={officers}
          selectedOfficerId={selectedOfficer?.user_id || null}
          onSelectOfficer={(officer) => setSelectedOfficer(officer)}
          onSetGeofenceToOfficer={alignGeofenceToOfficer}
        />

        <MapView
          officers={officers}
          geofence={geofence}
          selectedOfficer={selectedOfficer}
        />
      </div>

      {/* Enroll Field Inspection Modal */}
      <EnrollInspectionModal
        isOpen={isEnrollModalOpen}
        onClose={() => setIsEnrollModalOpen(false)}
        defaultLat={geofence.latitude}
        defaultLon={geofence.longitude}
      />
    </div>
  );
}

export default App;
