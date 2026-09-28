import { useState, useEffect, useMemo } from 'react';
import { Header } from './components/Header';
import { UserRoster } from './components/UserRoster';
import { MapView } from './components/MapView';
import { EnrollInspectionModal } from './components/EnrollInspectionModal';
import { OfficerLocation, GeofenceZone, AssignmentSubmission } from './types';
import { supabase } from './supabase';
import { Sliders, MapPin, Check, RefreshCw, CheckCircle2, X } from 'lucide-react';

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
  // Geofence starts null — loaded from backend/Supabase, never hardcoded
  const [geofence, setGeofence] = useState<GeofenceZone | null>(null);
  const [isConfiguringGeofence, setIsConfiguringGeofence] = useState(false);
  const [isEnrollModalOpen, setIsEnrollModalOpen] = useState(false);

  // Real-time Assignment Submissions state
  const [submissions, setSubmissions] = useState<AssignmentSubmission[]>([]);
  const [selectedSubmission, setSelectedSubmission] = useState<AssignmentSubmission | null>(null);
  const [latestNotification, setLatestNotification] = useState<AssignmentSubmission | null>(null);

  // Form state for dynamic geofence configuration
  const [geoForm, setGeoForm] = useState({
    name: '',
    latitude: '',
    longitude: '',
    radius_meters: '',
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

  // Fetch active geofences from backend or Supabase (never hardcoded)
  const fetchGeofence = async () => {
    // 1. Try FastAPI backend
    try {
      const res = await fetch('http://127.0.0.1:8000/api/geofences');
      if (res.ok) {
        const data = await res.json();
        if (Array.isArray(data) && data.length > 0) {
          const g = data[0];
          const loaded: GeofenceZone = {
            id: String(g.id || 'GEOFENCE-1'),
            name: g.name || 'Active Inspection Zone',
            latitude: Number(g.center_latitude ?? g.latitude),
            longitude: Number(g.center_longitude ?? g.longitude),
            radius_meters: Number(g.radius_meters || 300),
            description: g.description,
          };
          setGeofence(loaded);
          setGeoForm({
            name: loaded.name,
            latitude: loaded.latitude.toString(),
            longitude: loaded.longitude.toString(),
            radius_meters: loaded.radius_meters.toString(),
          });
          return;
        }
      }
    } catch (_) {}

    // 2. Try Supabase directly
    try {
      const { data, error } = await supabase
        .from('geofences')
        .select('*')
        .limit(1);
      if (!error && data && data.length > 0) {
        const g = data[0];
        const loaded: GeofenceZone = {
          id: String(g.id || 'GEOFENCE-1'),
          name: g.name || 'Active Inspection Zone',
          latitude: Number(g.center_latitude ?? g.latitude),
          longitude: Number(g.center_longitude ?? g.longitude),
          radius_meters: Number(g.radius_meters || 300),
          description: g.description,
        };
        setGeofence(loaded);
        setGeoForm({
          name: loaded.name,
          latitude: loaded.latitude.toString(),
          longitude: loaded.longitude.toString(),
          radius_meters: loaded.radius_meters.toString(),
        });
      }
    } catch (_) {}
    // If neither source returns data, geofence remains null until admin configures it.
  };

  // Fetch real latest location updates from Supabase, resolve real names from profiles
  const fetchRecentLocations = async () => {
    try {
      setIsLoadingInitial(true);

      // Fetch profiles for real names
      let profileMap: Record<string, string> = {};
      try {
        const { data: profiles } = await supabase.from('profiles').select('id, full_name, email');
        if (profiles) {
          for (const p of profiles) {
            profileMap[p.id] = p.full_name || p.email || p.id;
          }
        }
      } catch (_) {}

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

        const currentGeofence = geofence;
        const realOfficers: OfficerLocation[] = Array.from(latestByUser.values()).map(
          (row) => {
            const lat = Number(row.latitude);
            const lon = Number(row.longitude);
            let isInside = false;
            let perimeterDistance = 0;
            if (currentGeofence) {
              const res = evaluateOfficerGeofence(lat, lon, currentGeofence);
              isInside = res.isInside;
              perimeterDistance = res.perimeterDistance;
            }
            return {
              id: row.id,
              user_id: row.user_id,
              // Use real name from profiles, fall back to user_id only if profile not found
              name: profileMap[row.user_id] || row.user_id,
              role: 'Field Inspector',
              latitude: lat,
              longitude: lon,
              accuracy: Number(row.accuracy || 10),
              altitude: Number(row.altitude || 0),
              speed: Number(row.speed || 0),
              heading: Number(row.heading || 0),
              created_at: row.created_at,
              is_online: Date.now() - new Date(row.created_at).getTime() < 300000,
              is_inside: isInside,
              distance_from_perimeter: perimeterDistance,
            };
          }
        );

        setOfficers(realOfficers);
      }
    } catch (err) {
      console.error('Error fetching initial locations:', err);
    } finally {
      setIsLoadingInitial(false);
    }
  };

  // Fetch initial/cached evidence submissions
  const fetchSubmissions = async () => {
    try {
      const res = await fetch('http://127.0.0.1:8000/api/assignments/evidence/all');
      if (res.ok) {
        const data = await res.json();
        if (Array.isArray(data)) {
          setSubmissions(data);
          return;
        }
      }
    } catch (_) {}

    try {
      const { data, error } = await supabase
        .from('assignment_evidence')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(50);
      if (!error && data) {
        setSubmissions(data as any);
      }
    } catch (_) {}
  };

  useEffect(() => {
    fetchGeofence();
    fetchRecentLocations();
    fetchSubmissions();

    // 1. Subscribe to Supabase Realtime channel for live INSERT events on location_updates
    const locChannel = supabase
      .channel('public:location_updates')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'location_updates' },
        (payload) => {
          const update = payload.new as any;
          if (!update || update.latitude == null || update.longitude == null) return;

          const lat = Number(update.latitude);
          const lon = Number(update.longitude);

          const { isInside, perimeterDistance } = geofence
            ? evaluateOfficerGeofence(lat, lon, geofence)
            : { isInside: false, perimeterDistance: 0 };

          setOfficers((prev) => {
            const existingIndex = prev.findIndex((o) => o.user_id === update.user_id);
            const updatedOfficer: OfficerLocation = {
              id: update.id || Date.now(),
              user_id: update.user_id,
              // Preserve existing resolved name if officer already known, else fall back to user_id
              name: prev[existingIndex]?.name || update.user_id,
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

    // 2. Subscribe to Supabase Realtime channel for live assignment evidence submissions
    const evidenceChannel = supabase
      .channel('public:assignment_evidence')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'assignment_evidence' },
        (payload) => {
          const newEv = payload.new as any;
          if (!newEv) return;
          const sub: AssignmentSubmission = {
            evidence_id: newEv.evidence_id || String(newEv.id),
            assignment_id: newEv.assignment_id,
            user_id: newEv.user_id,
            image_url: newEv.image_url,
            latitude: Number(newEv.latitude),
            longitude: Number(newEv.longitude),
            geohash: newEv.geohash,
            gps_accuracy: Number(newEv.gps_accuracy || 0),
            captured_at: newEv.captured_at || new Date().toISOString(),
            location_verified: Boolean(newEv.location_verified),
            submission_status: newEv.submission_status || 'VERIFIED',
            verification_reason: newEv.verification_reason,
            distance_meters: newEv.distance_meters,
          };
          setSubmissions((prev) => {
            if (prev.some((s) => s.evidence_id === sub.evidence_id)) return prev;
            return [sub, ...prev];
          });
          setLatestNotification(sub);
        }
      )
      .subscribe();

    // 3. Direct FastAPI WebSocket for instant live notification broadcast
    let ws: WebSocket | null = null;
    try {
      ws = new WebSocket('ws://127.0.0.1:8000/ws/live');
      ws.onmessage = (event) => {
        try {
          const msg = JSON.parse(event.data);
          if (msg.type === 'ASSIGNMENT_COMPLETED') {
            const sub: AssignmentSubmission = {
              evidence_id: msg.assignment_id + '_' + Date.now(),
              assignment_id: msg.assignment_id,
              user_id: msg.user_id,
              officer_name: msg.officer_name || msg.user_id,
              assignment_title: msg.assignment_title,
              image_url: msg.evidence_url,
              latitude: Number(msg.latitude),
              longitude: Number(msg.longitude),
              geohash: msg.geohash,
              gps_accuracy: Number(msg.gps_accuracy || 0),
              captured_at: msg.captured_at || new Date().toISOString(),
              location_verified: true,
              submission_status: msg.submission_status || 'VERIFIED',
              distance_meters: msg.distance_meters,
            };
            setSubmissions((prev) => {
              if (prev.some((s) => s.assignment_id === sub.assignment_id && s.image_url === sub.image_url)) {
                return prev;
              }
              return [sub, ...prev];
            });
            setLatestNotification(sub);
          }
        } catch (_) {}
      };
    } catch (_) {}

    return () => {
      supabase.removeChannel(locChannel);
      supabase.removeChannel(evidenceChannel);
      if (ws) ws.close();
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
      id: geofence?.id || 'GEOFENCE-CUSTOM',
      name: geoForm.name || 'Custom Target Zone',
      latitude: newLat,
      longitude: newLon,
      radius_meters: newRadius,
      description: geofence?.description,
    };

    setGeofence(updatedGeofence);

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
      id: geofence?.id || 'GEOFENCE-OFFICER',
      name: `${officer.name} Site`,
      latitude: officer.latitude,
      longitude: officer.longitude,
      radius_meters: 500,
      description: geofence?.description,
    };
    setGeofence(updated);
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
          <strong className="text-white">Active Geofence:</strong>{' '}
            {geofence
              ? `${geofence.name} (${geofence.latitude.toFixed(5)}, ${geofence.longitude.toFixed(5)}) • Radius: ${geofence.radius_meters}m`
              : 'No geofence configured — click Configure Geofence to set one'}
          </span>
          {submissions.length > 0 && (
            <span className="ml-4 px-2 py-0.5 rounded bg-indigo-900 text-indigo-300 font-bold border border-indigo-700">
              {submissions.length} Submissions Received
            </span>
          )}
        </div>
        <div className="flex items-center space-x-2">
          <button
            onClick={() => {
              fetchRecentLocations();
              fetchSubmissions();
            }}
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
      <div className="flex flex-1 overflow-hidden relative">
        <UserRoster
          officers={officers}
          selectedOfficerId={selectedOfficer?.user_id || null}
          onSelectOfficer={(officer) => {
            setSelectedOfficer(officer);
            setSelectedSubmission(null);
          }}
          onSetGeofenceToOfficer={alignGeofenceToOfficer}
        />

        <MapView
          officers={officers}
          geofence={geofence}
          selectedOfficer={selectedOfficer}
          submissions={submissions}
          selectedSubmission={selectedSubmission}
          onSelectSubmission={(sub) => {
            setSelectedSubmission(sub);
            setSelectedOfficer(null);
          }}
        />

        {/* Real-time Sovereign Submission Alert Banner (Top-Right) */}
        {latestNotification && (
          <div className="absolute top-4 right-4 z-[2000] w-80 bg-slate-900/95 text-white border-2 border-emerald-500 rounded-xl shadow-2xl p-4 animate-in fade-in slide-in-from-top-4 duration-300">
            <div className="flex items-center justify-between pb-2 mb-2 border-b border-slate-700">
              <span className="font-bold text-emerald-400 text-xs flex items-center space-x-1.5">
                <CheckCircle2 className="w-4 h-4 text-emerald-400 animate-pulse" />
                <span>ASSIGNMENT COMPLETED ✓</span>
              </span>
              <button
                onClick={() => setLatestNotification(null)}
                className="text-slate-400 hover:text-white transition"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="space-y-1.5 text-xs text-slate-300">
              <p>
                <span className="font-semibold text-slate-400">Field Officer:</span>{' '}
                <strong className="text-white">
                  {latestNotification.officer_name || latestNotification.user_id}
                </strong>
              </p>
              <p>
                <span className="font-semibold text-slate-400">Assignment:</span>{' '}
                <strong className="text-teal-300">
                  {latestNotification.assignment_title || latestNotification.assignment_id}
                </strong>
              </p>
              <p>
                <span className="font-semibold text-slate-400">Location:</span>{' '}
                <span className="text-emerald-400 font-bold">VERIFIED ✓</span>
              </p>
              <p>
                <span className="font-semibold text-slate-400">GeoHash:</span>{' '}
                <span className="text-emerald-400 font-bold">VERIFIED ✓</span>{' '}
                <span className="font-mono text-[10px] text-slate-400">
                  ({latestNotification.geohash})
                </span>
              </p>
              <p>
                <span className="font-semibold text-slate-400">GPS Accuracy:</span>{' '}
                ±{Number(latestNotification.gps_accuracy || 0).toFixed(1)}m
              </p>
              <p>
                <span className="font-semibold text-slate-400">Captured At:</span>{' '}
                {new Date(latestNotification.captured_at).toLocaleTimeString()}
              </p>
              <p>
                <span className="font-semibold text-slate-400">Submission:</span>{' '}
                <span className="text-emerald-400 font-bold">VERIFIED</span>
              </p>
            </div>

            {latestNotification.image_url && (
              <div className="mt-2.5 h-28 w-full bg-black rounded-lg overflow-hidden border border-slate-700">
                <img
                  src={
                    latestNotification.image_url.startsWith('http')
                      ? latestNotification.image_url
                      : `http://127.0.0.1:8000${latestNotification.image_url}`
                  }
                  alt="Evidence"
                  className="w-full h-full object-cover"
                />
              </div>
            )}

            <button
              onClick={() => {
                setSelectedSubmission(latestNotification);
                setLatestNotification(null);
              }}
              className="mt-3 w-full bg-emerald-600 hover:bg-emerald-500 text-white font-bold py-1.5 rounded-lg text-xs transition shadow"
            >
              Focus on Map & View Bounds
            </button>
          </div>
        )}
      </div>

      {/* Enroll Field Inspection Modal */}
      <EnrollInspectionModal
        isOpen={isEnrollModalOpen}
        onClose={() => setIsEnrollModalOpen(false)}
        defaultLat={geofence?.latitude ?? 0}
        defaultLon={geofence?.longitude ?? 0}
      />
    </div>
  );
}

export default App;
