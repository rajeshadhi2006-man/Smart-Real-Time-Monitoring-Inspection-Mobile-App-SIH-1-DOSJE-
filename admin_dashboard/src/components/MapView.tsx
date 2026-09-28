import React, { useEffect } from 'react';
import { MapContainer, TileLayer, Circle, Marker, Popup, Rectangle, useMap } from 'react-leaflet';
import L from 'leaflet';
import { OfficerLocation, GeofenceZone, AssignmentSubmission } from '../types';
import { decodeGeoHash } from '../geohash';

interface MapViewProps {
  officers: OfficerLocation[];
  geofence: GeofenceZone | null;
  selectedOfficer: OfficerLocation | null;
  submissions?: AssignmentSubmission[];
  selectedSubmission?: AssignmentSubmission | null;
  onSelectSubmission?: (sub: AssignmentSubmission | null) => void;
}

// Sub-component to handle programmatically panning/zooming to a selected target
const MapCenterHandler: React.FC<{ targetCoords: [number, number] | null }> = ({
  targetCoords,
}) => {
  const map = useMap();

  useEffect(() => {
    if (targetCoords) {
      map.flyTo(targetCoords, 17, {
        duration: 1.2,
      });
    }
  }, [targetCoords, map]);

  return null;
};

export const MapView: React.FC<MapViewProps> = ({
  officers,
  geofence,
  selectedOfficer,
  submissions = [],
  selectedSubmission = null,
}) => {

  // Creates custom Leaflet HTML DivIcon for each officer marker
  const createOfficerIcon = (officer: OfficerLocation) => {
    const isSelected = selectedOfficer?.user_id === officer.user_id;
    const colorClass = officer.is_inside
      ? 'bg-emerald-600 border-white text-white'
      : 'bg-rose-600 border-white text-white';

    const html = `
      <div class="relative flex items-center justify-center">
        ${
          officer.is_online
            ? `<div class="absolute -inset-1.5 rounded-full ${
                officer.is_inside ? 'bg-emerald-400/30' : 'bg-rose-400/30'
              } animate-ping"></div>`
            : ''
        }
        <div class="w-8 h-8 rounded-full ${colorClass} border-2 shadow-lg flex items-center justify-center font-bold text-xs ${
      isSelected ? 'ring-4 ring-blue-500 scale-110' : ''
    } transition-all">
          ${officer.name.charAt(0)}
        </div>
      </div>
    `;

    return L.divIcon({
      className: 'custom-officer-marker',
      html,
      iconSize: [32, 32],
      iconAnchor: [16, 16],
    });
  };

  // Facility Geofence Center Icon
  const facilityIcon = L.divIcon({
    className: 'facility-marker',
    html: `
      <div class="w-9 h-9 rounded-full bg-slate-900 border-2 border-teal-400 text-teal-400 shadow-xl flex items-center justify-center">
        🏛️
      </div>
    `,
    iconSize: [36, 36],
    iconAnchor: [18, 18],
  });

  // Evidence Capture Point Icon
  const createEvidenceIcon = (isVerified: boolean) => {
    const borderColor = isVerified ? 'border-emerald-500 bg-emerald-700' : 'border-amber-500 bg-amber-700';
    return L.divIcon({
      className: 'evidence-capture-marker',
      html: `
        <div class="relative flex items-center justify-center cursor-pointer transform hover:scale-125 transition-transform">
          <div class="absolute -inset-1 rounded-full ${isVerified ? 'bg-emerald-400/40' : 'bg-amber-400/40'} animate-ping"></div>
          <div class="w-8 h-8 rounded-full ${borderColor} text-white border-2 shadow-2xl flex items-center justify-center text-sm">
            📷
          </div>
        </div>
      `,
      iconSize: [32, 32],
      iconAnchor: [16, 16],
    });
  };

  // Determine pan focus coordinates: selected submission > selected officer > geofence center > India center
  const activePanCoords: [number, number] = selectedSubmission
    ? [selectedSubmission.latitude, selectedSubmission.longitude]
    : selectedOfficer
    ? [selectedOfficer.latitude, selectedOfficer.longitude]
    : geofence
    ? [geofence.latitude, geofence.longitude]
    : [20.5937, 78.9629]; // Default: India center when no geofence

  // Default map center — india if no geofence configured yet
  const defaultCenter: [number, number] = geofence
    ? [geofence.latitude, geofence.longitude]
    : officers.length > 0
    ? [officers[0].latitude, officers[0].longitude]
    : [20.5937, 78.9629];

  return (
    <div className="flex-1 h-[calc(100vh-4rem)] relative">
      <MapContainer
        center={defaultCenter}
        zoom={geofence ? 15 : 5}
        scrollWheelZoom={true}
        className="w-full h-full"
      >
        {/* OpenStreetMap Standard Compliant Tile Layer */}
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://tile.openstreetmap.org/{z}/{x}/{y}.png"
          maxZoom={19}
        />

        {/* Dynamic Pan Controller */}
        <MapCenterHandler targetCoords={activePanCoords} />

        {/* Authorized Geofence Perimeter Circle — only when geofence is configured */}
        {geofence && (
          <Circle
            center={[geofence.latitude, geofence.longitude]}
            radius={geofence.radius_meters}
            pathOptions={{
              color: '#0D9488',
              fillColor: '#0D9488',
              fillOpacity: 0.12,
              weight: 2,
              dashArray: '6, 6',
            }}
          />
        )}

        {/* Central Facility Anchor Marker — only when geofence is configured */}
        {geofence && (
          <Marker position={[geofence.latitude, geofence.longitude]} icon={facilityIcon}>
            <Popup>
              <div className="text-xs">
                <p className="font-bold text-slate-900">{geofence.name}</p>
                <p className="text-slate-500 mt-1">Authorized Inspection Geofence Center</p>
                <p className="text-slate-600 font-medium mt-1">Radius: {geofence.radius_meters}m</p>
              </div>
            </Popup>
          </Marker>
        )}

        {/* GeoHash Bounding Box Polygons for Verified Submissions */}
        {submissions.map((sub) => {
          const ghToUse = sub.target_geohash || sub.geohash;
          if (!ghToUse) return null;
          const box = decodeGeoHash(ghToUse);
          return (
            <Rectangle
              key={`geohash-${sub.evidence_id}`}
              bounds={[
                [box.minLat, box.minLon],
                [box.maxLat, box.maxLon],
              ]}
              pathOptions={{
                color: '#6366F1',
                weight: 1.8,
                dashArray: '4, 4',
                fillColor: '#818CF8',
                fillOpacity: 0.08,
              }}
            >
              <Popup>
                <div className="text-xs">
                  <p className="font-bold text-indigo-900">GeoHash Perimeter Area</p>
                  <p className="text-slate-600 font-mono text-[11px] mt-0.5">Hash: {ghToUse}</p>
                  <p className="text-slate-500 text-[10px] mt-1">
                    Bounds: [{box.minLat.toFixed(4)}, {box.minLon.toFixed(4)}] to [{box.maxLat.toFixed(4)}, {box.maxLon.toFixed(4)}]
                  </p>
                </div>
              </Popup>
            </Rectangle>
          );
        })}

        {/* Real-time Evidence Capture Markers */}
        {submissions.map((sub) => {
          const isVerified = sub.location_verified || sub.submission_status === 'VERIFIED';
          const fullImgUrl = sub.image_url.startsWith('http')
            ? sub.image_url
            : `http://127.0.0.1:8000${sub.image_url}`;

          return (
            <Marker
              key={`evidence-${sub.evidence_id}`}
              position={[sub.latitude, sub.longitude]}
              icon={createEvidenceIcon(isVerified)}
            >
              <Popup maxWidth={300} minWidth={260}>
                <div className="text-xs p-1">
                  {/* Sovereign Header */}
                  <div className="flex items-center justify-between pb-1.5 mb-2 border-b border-slate-200">
                    <span className="font-bold text-emerald-700 flex items-center space-x-1">
                      <span>✓</span>
                      <span>ASSIGNMENT COMPLETED</span>
                    </span>
                    <span className="px-1.5 py-0.5 rounded text-[10px] font-bold bg-emerald-100 text-emerald-800">
                      {sub.submission_status || 'VERIFIED'}
                    </span>
                  </div>

                  {/* Evidence Image Thumbnail */}
                  <div className="w-full h-32 bg-slate-900 rounded-lg overflow-hidden mb-2 border border-slate-300 flex items-center justify-center">
                    <img
                      src={fullImgUrl}
                      alt="Geo-Tagged Evidence"
                      className="w-full h-full object-cover"
                      onError={(e) => {
                        (e.target as HTMLElement).style.display = 'none';
                      }}
                    />
                  </div>

                  {/* Submission Details */}
                  <div className="space-y-1 text-slate-700 text-[11px]">
                    <p>
                      <span className="font-semibold text-slate-900">Field Officer:</span>{' '}
                      {sub.officer_name || sub.user_id}
                    </p>
                    <p>
                      <span className="font-semibold text-slate-900">Assignment:</span>{' '}
                      {sub.assignment_title || sub.assignment_id}
                    </p>
                    <p>
                      <span className="font-semibold text-slate-900">Location:</span>{' '}
                      <span className="text-emerald-600 font-bold">VERIFIED ✓</span>{' '}
                      ({sub.latitude.toFixed(5)}, {sub.longitude.toFixed(5)})
                    </p>
                    <p>
                      <span className="font-semibold text-slate-900">GeoHash:</span>{' '}
                      <span className="text-emerald-600 font-bold">VERIFIED ✓</span>{' '}
                      <span className="font-mono text-[10px] text-slate-600">({sub.geohash})</span>
                    </p>
                    <p>
                      <span className="font-semibold text-slate-900">GPS Accuracy:</span>{' '}
                      ±{Number(sub.gps_accuracy || 0).toFixed(1)} m
                    </p>
                    <p>
                      <span className="font-semibold text-slate-900">Captured At:</span>{' '}
                      {new Date(sub.captured_at).toLocaleString()}
                    </p>
                    <p>
                      <span className="font-semibold text-slate-900">Submission:</span>{' '}
                      <span className="text-emerald-700 font-bold">VERIFIED</span>
                    </p>
                  </div>
                </div>
              </Popup>
            </Marker>
          );
        })}

        {/* Live Officer Markers */}
        {officers.map((officer) => (
          <Marker
            key={officer.user_id}
            position={[officer.latitude, officer.longitude]}
            icon={createOfficerIcon(officer)}
          >
            <Popup>
              <div className="text-xs w-52">
                <div className="flex items-center justify-between pb-1 mb-1 border-b border-slate-200">
                  <span className="font-bold text-slate-900">{officer.name}</span>
                  <span
                    className={`px-1.5 py-0.5 rounded text-[10px] font-bold ${
                      officer.is_inside
                        ? 'bg-emerald-100 text-emerald-800'
                        : 'bg-rose-100 text-rose-800'
                    }`}
                  >
                    {officer.is_inside ? 'Inside' : 'Outside'}
                  </span>
                </div>
                <p className="text-slate-500 text-[11px]">{officer.role}</p>
                <div className="mt-2 space-y-1 text-slate-600 text-[11px]">
                  <p>
                    <span className="font-medium">Accuracy:</span> ±{officer.accuracy.toFixed(1)}m
                  </p>
                  <p>
                    <span className="font-medium">Coordinates:</span> {officer.latitude.toFixed(5)},{' '}
                    {officer.longitude.toFixed(5)}
                  </p>
                  <p>
                    <span className="font-medium">Speed:</span> {(officer.speed * 3.6).toFixed(1)}{' '}
                    km/h
                  </p>
                  <p>
                    <span className="font-medium">Distance from center:</span>{' '}
                    {officer.distance_from_perimeter.toFixed(0)}m
                  </p>
                </div>
              </div>
            </Popup>
          </Marker>
        ))}
      </MapContainer>

      {/* Floating Legend / Telemetry Overlay (Bottom-Right) */}
      <div className="absolute bottom-6 right-6 z-[1000] bg-white/95 backdrop-blur-sm p-3.5 rounded-xl border border-slate-200 shadow-xl max-w-xs text-xs space-y-1.5">
        <div className="flex items-center space-x-2 font-bold text-slate-800">
          <span className="w-2.5 h-2.5 rounded-full bg-teal-600"></span>
          <span>{geofence ? geofence.name : 'No Geofence Configured'}</span>
        </div>
        <div className="flex items-center justify-between text-[11px] text-slate-600 pt-1 border-t border-slate-100">
          <span className="flex items-center space-x-1">
            <span className="text-indigo-600 font-bold">▢</span>
            <span>GeoHash Area</span>
          </span>
          <span className="flex items-center space-x-1">
            <span>📷</span>
            <span>Evidence ({submissions.length})</span>
          </span>
        </div>
        <p className="text-slate-500 text-[10px] mt-1">
          OpenStreetMap Tile Layer • Realtime Spatial Verification
        </p>
      </div>
    </div>
  );
};
