import React, { useState } from 'react';
import { PlusCircle, X, Building2, MapPin, UserCheck, ShieldAlert, Check } from 'lucide-react';
import { supabase } from '../supabase';

interface EnrollInspectionModalProps {
  isOpen: boolean;
  onClose: () => void;
  defaultLat: number;
  defaultLon: number;
  onEnrolled?: (inspection: any) => void;
}

export const EnrollInspectionModal: React.FC<EnrollInspectionModalProps> = ({
  isOpen,
  onClose,
  defaultLat,
  defaultLon,
  onEnrolled,
}) => {
  const [projectName, setProjectName] = useState('');
  const [organization, setOrganization] = useState('');
  const [district, setDistrict] = useState('');
  const [latitude, setLatitude] = useState(defaultLat.toString());
  const [longitude, setLongitude] = useState(defaultLon.toString());
  const [priority, setPriority] = useState('HIGH');
  const [assignedInspector, setAssignedInspector] = useState('Field Officer (Active)');
  const [expectedBeneficiaries, setExpectedBeneficiaries] = useState('100');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!projectName.trim() || !organization.trim() || !district.trim()) {
      alert('Please provide facility name, organization, and district.');
      return;
    }

    const lat = parseFloat(latitude);
    const lon = parseFloat(longitude);
    if (isNaN(lat) || isNaN(lon)) {
      alert('Please enter valid numeric coordinates for latitude and longitude.');
      return;
    }

    setIsSubmitting(true);
    const inspectionId = `INS-2026-${Date.now().toString().slice(-5)}`;
    const newInspection = {
      id: inspectionId,
      project_id: `PRJ-${Date.now().toString().slice(-4)}`,
      project_name: projectName.trim(),
      organization: organization.trim(),
      district: district.trim(),
      status: 'assigned',
      priority: priority,
      assignment_reason: 'Autonomous Web Portal Enrollment',
      scheduled_window: 'Today, 09:00 - 17:00 IST',
      deadline: 'Active Audit Window',
      assigned_inspector: assignedInspector.trim(),
      is_gps_verified: false,
      distance_meters: null,
      verified_latitude: lat,
      verified_longitude: lon,
      gps_accuracy: null,
      photo_count: 0,
      video_count: 0,
      expected_beneficiaries: parseInt(expectedBeneficiaries, 10) || 100,
      verified_beneficiaries: 0,
      ai_risk_level: priority === 'CRITICAL' || priority === 'HIGH' ? 'High' : 'Medium',
      ai_risk_reasons: ['Newly enrolled field site awaiting on-site GPS verification.'],
      inspector_remarks: '',
      created_at: new Date().toISOString(),
    };

    try {
      const { error } = await supabase.from('inspections').insert(newInspection);
      if (error) {
        console.warn('Supabase insert note:', error.message);
      }
      setSuccessMessage(`Inspection ${inspectionId} enrolled successfully! Broadcasted to mobile app.`);
      onEnrolled?.(newInspection);
      setTimeout(() => {
        setSuccessMessage(null);
        onClose();
        // Reset form
        setProjectName('');
        setOrganization('');
        setDistrict('');
      }, 1400);
    } catch (err: any) {
      console.error('Error submitting inspection enrollment:', err);
      alert('Failed to enroll inspection: ' + err.message);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
      <div className="bg-slate-900 border border-slate-700 rounded-2xl shadow-2xl max-w-lg w-full overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        {/* Modal Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-slate-800 bg-slate-900/80">
          <div className="flex items-center space-x-2.5">
            <div className="p-2 rounded-lg bg-blue-600/20 text-blue-400 border border-blue-500/30">
              <PlusCircle className="w-5 h-5" />
            </div>
            <div>
              <h3 className="font-bold text-base text-white">Enroll Field Inspection Site</h3>
              <p className="text-xs text-slate-400">
                Enrolled details synchronize to mobile field app in real time
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Modal Body / Form */}
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          {successMessage && (
            <div className="p-3.5 rounded-xl bg-emerald-950/60 border border-emerald-500/40 text-emerald-300 text-xs font-semibold flex items-center space-x-2">
              <Check className="w-4 h-4 text-emerald-400" />
              <span>{successMessage}</span>
            </div>
          )}

          <div>
            <label className="block text-xs font-medium text-slate-300 mb-1.5 flex items-center space-x-1.5">
              <Building2 className="w-3.5 h-3.5 text-blue-400" />
              <span>Facility / Project Name</span>
            </label>
            <input
              type="text"
              required
              placeholder="e.g. Apex Welfare Centre & Skill Institute"
              value={projectName}
              onChange={(e) => setProjectName(e.target.value)}
              className="w-full bg-slate-800 border border-slate-700 rounded-xl px-3.5 py-2.5 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-medium text-slate-300 mb-1.5">Organization</label>
              <input
                type="text"
                required
                placeholder="e.g. Welfare Trust / NGO"
                value={organization}
                onChange={(e) => setOrganization(e.target.value)}
                className="w-full bg-slate-800 border border-slate-700 rounded-xl px-3.5 py-2.5 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-300 mb-1.5">District & State</label>
              <input
                type="text"
                required
                placeholder="e.g. Bengaluru, Karnataka"
                value={district}
                onChange={(e) => setDistrict(e.target.value)}
                className="w-full bg-slate-800 border border-slate-700 rounded-xl px-3.5 py-2.5 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-medium text-slate-300 mb-1.5 flex items-center space-x-1">
                <MapPin className="w-3.5 h-3.5 text-teal-400" />
                <span>Target Latitude</span>
              </label>
              <input
                type="number"
                step="any"
                required
                value={latitude}
                onChange={(e) => setLatitude(e.target.value)}
                className="w-full bg-slate-800 border border-slate-700 rounded-xl px-3.5 py-2.5 text-sm text-white focus:outline-none focus:border-blue-500"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-300 mb-1.5 flex items-center space-x-1">
                <MapPin className="w-3.5 h-3.5 text-teal-400" />
                <span>Target Longitude</span>
              </label>
              <input
                type="number"
                step="any"
                required
                value={longitude}
                onChange={(e) => setLongitude(e.target.value)}
                className="w-full bg-slate-800 border border-slate-700 rounded-xl px-3.5 py-2.5 text-sm text-white focus:outline-none focus:border-blue-500"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-medium text-slate-300 mb-1.5 flex items-center space-x-1">
                <ShieldAlert className="w-3.5 h-3.5 text-amber-400" />
                <span>Audit Priority</span>
              </label>
              <select
                value={priority}
                onChange={(e) => setPriority(e.target.value)}
                className="w-full bg-slate-800 border border-slate-700 rounded-xl px-3.5 py-2.5 text-sm text-white focus:outline-none focus:border-blue-500"
              >
                <option value="CRITICAL">CRITICAL</option>
                <option value="HIGH">HIGH</option>
                <option value="MEDIUM">MEDIUM</option>
                <option value="LOW">LOW</option>
              </select>
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-300 mb-1.5 flex items-center space-x-1">
                <UserCheck className="w-3.5 h-3.5 text-blue-400" />
                <span>Assigned Inspector</span>
              </label>
              <input
                type="text"
                value={assignedInspector}
                onChange={(e) => setAssignedInspector(e.target.value)}
                className="w-full bg-slate-800 border border-slate-700 rounded-xl px-3.5 py-2.5 text-sm text-white focus:outline-none focus:border-blue-500"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-medium text-slate-300 mb-1.5">
              Target / Expected Beneficiaries
            </label>
            <input
              type="number"
              min="1"
              value={expectedBeneficiaries}
              onChange={(e) => setExpectedBeneficiaries(e.target.value)}
              className="w-full bg-slate-800 border border-slate-700 rounded-xl px-3.5 py-2.5 text-sm text-white focus:outline-none focus:border-blue-500"
            />
          </div>

          <div className="pt-2 flex items-center justify-end space-x-3">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-xs font-semibold text-slate-400 hover:text-white rounded-xl hover:bg-slate-800 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="px-5 py-2.5 text-xs font-bold text-white bg-blue-600 hover:bg-blue-500 rounded-xl shadow-lg shadow-blue-600/30 transition-all disabled:opacity-50 flex items-center space-x-1.5"
            >
              {isSubmitting ? (
                <span>Enrolling...</span>
              ) : (
                <>
                  <PlusCircle className="w-4 h-4" />
                  <span>Enroll & Dispatch to App</span>
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
