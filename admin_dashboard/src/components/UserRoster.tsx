import React, { useState } from 'react';
import { Search, Navigation, Compass, Crosshair } from 'lucide-react';
import { OfficerLocation } from '../types';

interface UserRosterProps {
  officers: OfficerLocation[];
  selectedOfficerId: string | null;
  onSelectOfficer: (officer: OfficerLocation) => void;
  onSetGeofenceToOfficer?: (officer: OfficerLocation) => void;
}

export const UserRoster: React.FC<UserRosterProps> = ({
  officers,
  selectedOfficerId,
  onSelectOfficer,
  onSetGeofenceToOfficer,
}) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'online' | 'offline'>('all');
  const [geofenceFilter, setGeofenceFilter] = useState<'all' | 'inside' | 'outside'>('all');

  const filteredOfficers = officers.filter((officer) => {
    const matchesSearch =
      officer.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      officer.user_id.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesStatus =
      statusFilter === 'all' ||
      (statusFilter === 'online' ? officer.is_online : !officer.is_online);

    const matchesGeofence =
      geofenceFilter === 'all' ||
      (geofenceFilter === 'inside' ? officer.is_inside : !officer.is_inside);

    return matchesSearch && matchesStatus && matchesGeofence;
  });

  const formatTimeAgo = (dateStr: string) => {
    const diff = Math.floor((Date.now() - new Date(dateStr).getTime()) / 1000);
    if (diff < 5) return 'Just now';
    if (diff < 60) return `${diff}s ago`;
    if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
    return `${Math.floor(diff / 3600)}h ago`;
  };

  return (
    <aside className="w-96 bg-white border-r border-slate-200 flex flex-col h-[calc(100vh-4rem)] shadow-sm">
      {/* Title & Filters */}
      <div className="p-4 border-b border-slate-200">
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-sm font-extrabold uppercase tracking-wider text-slate-800 flex items-center gap-2">
            <Navigation className="w-4 h-4 text-blue-600" />
            ACTIVE USERS ({filteredOfficers.length})
          </h2>
        </div>

        {/* Search Input */}
        <div className="relative mb-3">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
          <input
            type="text"
            placeholder="Search officer or ID..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-9 pr-3 py-1.5 text-xs bg-slate-50 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white"
          />
        </div>

        {/* Filter Pills */}
        <div className="flex items-center justify-between gap-2">
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value as any)}
            className="text-xs bg-slate-50 border border-slate-200 rounded-md px-2 py-1 text-slate-600 focus:outline-none"
          >
            <option value="all">Status: All</option>
            <option value="online">Online Only</option>
            <option value="offline">Offline Only</option>
          </select>

          <select
            value={geofenceFilter}
            onChange={(e) => setGeofenceFilter(e.target.value as any)}
            className="text-xs bg-slate-50 border border-slate-200 rounded-md px-2 py-1 text-slate-600 focus:outline-none"
          >
            <option value="all">Geofence: All</option>
            <option value="inside">Inside Area</option>
            <option value="outside">Outside Area</option>
          </select>
        </div>
      </div>

      {/* Officer Items List */}
      <div className="flex-1 overflow-y-auto divide-y divide-slate-100">
        {filteredOfficers.length === 0 ? (
          <div className="p-8 text-center flex flex-col items-center justify-center h-64 text-slate-400 text-xs">
            <div className="w-12 h-12 rounded-full bg-blue-50 border border-blue-200 flex items-center justify-center text-blue-600 mb-3 animate-pulse">
              <Navigation className="w-6 h-6" />
            </div>
            <p className="font-bold text-slate-700 text-sm mb-1">
              Awaiting Live Telemetry
            </p>
            <p className="text-slate-500 text-xs max-w-xs leading-relaxed">
              No field officers are currently streaming. Open the mobile application or client and tap <strong>"Start Tracking"</strong> to broadcast live GPS telemetry.
            </p>
          </div>
        ) : (
          filteredOfficers.map((officer) => {
            const isSelected = officer.user_id === selectedOfficerId;

            return (
              <div
                key={officer.user_id}
                onClick={() => onSelectOfficer(officer)}
                className={`p-3.5 hover:bg-slate-50 cursor-pointer transition-colors ${
                  isSelected ? 'bg-blue-50/70 border-l-4 border-blue-600' : ''
                }`}
              >
                <div className="flex items-start justify-between">
                  <div className="flex items-center space-x-2.5">
                    <div
                      className={`w-2.5 h-2.5 rounded-full ${
                        officer.is_online ? 'bg-emerald-500 animate-pulse' : 'bg-slate-400'
                      }`}
                    />
                    <div>
                      <h3 className="text-xs font-bold text-slate-800">{officer.name}</h3>
                      <p className="text-[11px] text-slate-500">{officer.user_id}</p>
                    </div>
                  </div>

                  {/* Inside / Outside Badge */}
                  <span
                    className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${
                      officer.is_inside
                        ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                        : 'bg-rose-50 text-rose-700 border-rose-200'
                    }`}
                  >
                    {officer.is_inside ? 'Inside Area' : 'Outside Area'}
                  </span>
                </div>

                {/* Sub-metrics */}
                <div className="mt-2 flex items-center justify-between text-[11px] text-slate-500">
                  <span className="flex items-center gap-1">
                    <Crosshair className="w-3 h-3 text-slate-400" />
                    Accuracy: ±{officer.accuracy.toFixed(0)}m
                  </span>
                  <span className="flex items-center gap-1">
                    <Compass className="w-3 h-3 text-slate-400" />
                    Updated: {formatTimeAgo(officer.created_at)}
                  </span>
                </div>

                {/* Distance breakdown & quick align button */}
                <div className="mt-2 flex items-center justify-between">
                  <p className="text-[10px] text-slate-600">
                    {officer.latitude.toFixed(5)}, {officer.longitude.toFixed(5)}
                  </p>
                  {onSetGeofenceToOfficer && (
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        onSetGeofenceToOfficer(officer);
                      }}
                      className="text-[10px] text-blue-600 hover:text-blue-800 font-semibold underline"
                    >
                      Set Geofence Here
                    </button>
                  )}
                </div>
              </div>
            );
          })
        )}
      </div>
    </aside>
  );
};
