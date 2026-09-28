import React, { useEffect } from 'react';
import { MapContainer, TileLayer, Circle, Marker, Popup, useMap } from 'react-leaflet';
import L from 'leaflet';
import { OfficerLocation, GeofenceZone } from '../types';

interface MapViewProps {
  officers: OfficerLocation[];
  geofence: GeofenceZone;
  selectedOfficer: OfficerLocation | null;
}

// Sub-component to handle programmatically panning/zooming to a selected officer
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
}) => {
  const defaultCenter: [number, number] = [geofence.latitude, geofence.longitude];

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

  return (
    <div className="flex-1 h-[calc(100vh-4rem)] relative">
      <MapContainer
        center={defaultCenter}
        zoom={15}
        scrollWheelZoom={true}
        className="w-full h-full"
      >
        {/* OpenStreetMap Standard Compliant Tile Layer */}
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://tile.openstreetmap.org/{z}/{x}/{y}.png"
          maxZoom={19}
        />

        {/* Pan Controller */}
        <MapCenterHandler
          targetCoords={
            selectedOfficer
              ? [selectedOfficer.latitude, selectedOfficer.longitude]
              : [geofence.latitude, geofence.longitude]
          }
        />

        {/* Authorized Geofence Perimeter Circle */}
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

        {/* Central Facility Anchor Marker */}
        <Marker position={[geofence.latitude, geofence.longitude]} icon={facilityIcon}>
          <Popup>
            <div className="text-xs">
              <p className="font-bold text-slate-900">{geofence.name}</p>
              <p className="text-slate-500 mt-1">Authorized Inspection Geofence Center</p>
              <p className="text-slate-600 font-medium mt-1">Radius: {geofence.radius_meters}m</p>
            </div>
          </Popup>
        </Marker>

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

      {/* Floating Geofence Info Overlay (Bottom-Right) */}
      <div className="absolute bottom-6 right-6 z-[1000] bg-white/95 backdrop-blur-sm p-3.5 rounded-xl border border-slate-200 shadow-xl max-w-xs text-xs">
        <div className="flex items-center space-x-2 font-bold text-slate-800">
          <span className="w-2.5 h-2.5 rounded-full bg-teal-600"></span>
          <span>{geofence.name}</span>
        </div>
        <p className="text-slate-500 text-[11px] mt-1">
          Radius: {geofence.radius_meters}m • OpenStreetMap Tile Layer
        </p>
      </div>
    </div>
  );
};
