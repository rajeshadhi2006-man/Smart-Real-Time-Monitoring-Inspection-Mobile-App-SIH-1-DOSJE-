import React from 'react';
import { ShieldCheck, Radio, Users, CheckCircle2, AlertTriangle, PlusCircle } from 'lucide-react';

interface HeaderProps {
  activeCount: number;
  insideCount: number;
  outsideCount: number;
  isRealtimeConnected: boolean;
  onOpenEnrollModal?: () => void;
}

export const Header: React.FC<HeaderProps> = ({
  activeCount,
  insideCount,
  outsideCount,
  isRealtimeConnected,
  onOpenEnrollModal,
}) => {
  return (
    <header className="bg-slate-900 text-white border-b border-slate-800 shadow-md">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Brand & Emblem */}
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 rounded-lg bg-blue-600 flex items-center justify-center text-white shadow-md">
              <ShieldCheck className="w-6 h-6" />
            </div>
            <div>
              <div className="flex items-center space-x-2">
                <span className="font-extrabold text-base tracking-tight text-white">
                  GOVERNMENT MONITORING DASHBOARD
                </span>
                <span className="bg-blue-500/20 text-blue-400 text-xs font-semibold px-2 py-0.5 rounded border border-blue-500/30">
                  SIH 26095
                </span>
              </div>
              <p className="text-xs text-slate-400">
                Ministry of Social Justice and Empowerment • Autonomous Field Telemetry
              </p>
            </div>
          </div>

          {/* Realtime Stats Banner */}
          <div className="flex items-center space-x-6">
            <div className="flex items-center space-x-2 bg-slate-800/80 px-3.5 py-1.5 rounded-lg border border-slate-700">
              <Users className="w-4 h-4 text-blue-400" />
              <span className="text-xs text-slate-300">Active Users:</span>
              <span className="text-sm font-bold text-white">{activeCount}</span>
            </div>

            <div className="flex items-center space-x-2 bg-emerald-950/40 px-3.5 py-1.5 rounded-lg border border-emerald-500/30">
              <CheckCircle2 className="w-4 h-4 text-emerald-400" />
              <span className="text-xs text-emerald-200">Inside Area:</span>
              <span className="text-sm font-bold text-emerald-400">{insideCount}</span>
            </div>

            <div className="flex items-center space-x-2 bg-rose-950/40 px-3.5 py-1.5 rounded-lg border border-rose-500/30">
              <AlertTriangle className="w-4 h-4 text-rose-400" />
              <span className="text-xs text-rose-200">Outside Area:</span>
              <span className="text-sm font-bold text-rose-400">{outsideCount}</span>
            </div>

            {/* Live Realtime Pulsing Status */}
            <div className="flex items-center space-x-2 bg-slate-800 px-3 py-1.5 rounded-full border border-slate-700">
              <Radio
                className={`w-3.5 h-3.5 ${
                  isRealtimeConnected ? 'text-emerald-400 animate-pulse' : 'text-amber-400'
                }`}
              />
              <span className="text-xs font-medium text-slate-300">
                {isRealtimeConnected ? 'Supabase Realtime' : 'Awaiting Link'}
              </span>
            </div>

            {/* Enroll Inspection Action Button */}
            {onOpenEnrollModal && (
              <button
                onClick={onOpenEnrollModal}
                className="flex items-center space-x-1.5 bg-blue-600 hover:bg-blue-500 text-white text-xs font-bold px-3 py-1.5 rounded-lg shadow-md hover:shadow-blue-600/30 transition-all cursor-pointer"
              >
                <PlusCircle className="w-4 h-4" />
                <span>Enroll Inspection</span>
              </button>
            )}
          </div>
        </div>
      </div>
    </header>
  );
};
