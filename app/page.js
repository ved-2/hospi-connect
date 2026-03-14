"use client";

import { useMemo, useState } from "react";

const urgencyWeights = {
  critical: 40,
  urgent: 28,
  moderate: 16,
  routine: 8,
};

const diseaseCatalog = {
  cardiac: {
    label: "Cardiac emergency",
    specialty: "Cardiology",
    resourceCategory: "ICU_BED",
    ambulancePreferred: true,
  },
  trauma: {
    label: "Trauma and injury",
    specialty: "Trauma Care",
    resourceCategory: "ICU_BED",
    ambulancePreferred: true,
  },
  respiratory: {
    label: "Respiratory distress",
    specialty: "Pulmonology",
    resourceCategory: "VENTILATOR",
    ambulancePreferred: true,
  },
  neuro: {
    label: "Neurological symptoms",
    specialty: "Neurology",
    resourceCategory: "ICU_BED",
    ambulancePreferred: false,
  },
  maternity: {
    label: "Maternity care",
    specialty: "Obstetrics",
    resourceCategory: "GENERAL_BED",
    ambulancePreferred: false,
  },
  general: {
    label: "General admission",
    specialty: "Internal Medicine",
    resourceCategory: "GENERAL_BED",
    ambulancePreferred: false,
  },
};

const hospitalsSeed = [
  {
    id: "h-101",
    name: "Apex Multispeciality",
    type: "Private tertiary hospital",
    city: "South Delhi",
    distanceKm: 3.4,
    emergencyStatus: "green",
    specialties: ["Cardiology", "Pulmonology", "Internal Medicine"],
    contactChannels: ["Bed Desk", "Emergency Command"],
    resources: [
      { category: "ICU_BED", available: 4, total: 18 },
      { category: "GENERAL_BED", available: 16, total: 60 },
      { category: "DOCTOR", available: 8, total: 18 },
      { category: "VENTILATOR", available: 3, total: 10 },
      { category: "AMBULANCE", available: 2, total: 5 },
    ],
    incomingCitizenIds: ["req-301"],
    emergencyRequests: [
      {
        id: "er-01",
        requestingHospital: "Lotus Care Centre",
        need: "ICU bed + cardiology specialist",
        priority: "critical",
        etaMinutes: 11,
        status: "Matched",
      },
    ],
  },
  {
    id: "h-102",
    name: "CityCare Government Hospital",
    type: "Public emergency network hospital",
    city: "Noida",
    distanceKm: 7.8,
    emergencyStatus: "amber",
    specialties: ["Trauma Care", "Neurology", "Internal Medicine"],
    contactChannels: ["Trauma Desk", "Transfer Desk"],
    resources: [
      { category: "ICU_BED", available: 2, total: 24 },
      { category: "GENERAL_BED", available: 22, total: 120 },
      { category: "DOCTOR", available: 11, total: 28 },
      { category: "VENTILATOR", available: 1, total: 12 },
      { category: "AMBULANCE", available: 4, total: 6 },
    ],
    incomingCitizenIds: ["req-302"],
    emergencyRequests: [
      {
        id: "er-02",
        requestingHospital: "Metro Heart Unit",
        need: "Ventilator backup",
        priority: "urgent",
        etaMinutes: 24,
        status: "In transfer",
      },
    ],
  },
  {
    id: "h-103",
    name: "Sunrise Women and Child Institute",
    type: "Speciality care hospital",
    city: "Gurugram",
    distanceKm: 10.6,
    emergencyStatus: "green",
    specialties: ["Obstetrics", "Pediatrics", "Internal Medicine"],
    contactChannels: ["Admission Cell", "Referral Desk"],
    resources: [
      { category: "ICU_BED", available: 1, total: 8 },
      { category: "GENERAL_BED", available: 12, total: 42 },
      { category: "DOCTOR", available: 5, total: 12 },
      { category: "VENTILATOR", available: 1, total: 4 },
      { category: "AMBULANCE", available: 1, total: 2 },
    ],
    incomingCitizenIds: [],
    emergencyRequests: [],
  },
  {
    id: "h-104",
    name: "Metro Heart and Neuro",
    type: "Advanced speciality hub",
    city: "Central Delhi",
    distanceKm: 5.2,
    emergencyStatus: "red",
    specialties: ["Cardiology", "Neurology", "Trauma Care"],
    contactChannels: ["Command Center", "Ambulance Dock"],
    resources: [
      { category: "ICU_BED", available: 1, total: 20 },
      { category: "GENERAL_BED", available: 9, total: 70 },
      { category: "DOCTOR", available: 6, total: 20 },
      { category: "VENTILATOR", available: 2, total: 14 },
      { category: "AMBULANCE", available: 1, total: 4 },
    ],
    incomingCitizenIds: [],
    emergencyRequests: [
      {
        id: "er-03",
        requestingHospital: "Green Valley Hospital",
        need: "Stroke-ready ICU transfer",
        priority: "critical",
        etaMinutes: 14,
        status: "Awaiting lock",
      },
    ],
  },
];

const citizensSeed = [
  {
    id: "cit-1",
    name: "Riya Sharma",
    age: 34,
    gender: "Female",
    phone: "+91 98XXXXXX41",
    email: "riya@example.com",
    homeLocation: "Lajpat Nagar",
    emergencyContacts: ["Mohit Sharma"],
    authProfile: "citizen",
  },
  {
    id: "cit-2",
    name: "Arjun Mehta",
    age: 56,
    gender: "Male",
    phone: "+91 99XXXXXX08",
    email: "arjun@example.com",
    homeLocation: "Noida Sector 62",
    emergencyContacts: ["Naina Mehta"],
    authProfile: "citizen",
  },
];

const requestsSeed = [
  {
    id: "req-301",
    citizenId: "cit-2",
    citizenName: "Arjun Mehta",
    symptomSummary: "Chest pain, shortness of breath, unstable vitals",
    diseaseCategory: "cardiac",
    urgencyLevel: "critical",
    specialtyNeeded: "Cardiology",
    currentLocation: "Noida Sector 62",
    preferredRadius: 12,
    status: "PENDING_HOSPITAL_REVIEW",
    submittedAt: "2026-03-14T09:12:00Z",
    selectedHospitalId: "h-101",
    recommendedHospitalIds: ["h-101", "h-104"],
  },
  {
    id: "req-302",
    citizenId: "cit-1",
    citizenName: "Riya Sharma",
    symptomSummary: "Head injury after road accident",
    diseaseCategory: "trauma",
    urgencyLevel: "urgent",
    specialtyNeeded: "Trauma Care",
    currentLocation: "AIIMS Flyover",
    preferredRadius: 10,
    status: "MATCHED",
    submittedAt: "2026-03-14T09:18:00Z",
    selectedHospitalId: "h-102",
    recommendedHospitalIds: ["h-102", "h-104"],
  },
];

const transferSeed = [
  {
    id: "tr-11",
    requestId: "er-02",
    originHospitalId: "h-104",
    destinationHospitalId: "h-102",
    transportType: "Advanced life support ambulance",
    ambulanceId: "AMB-22",
    eta: "18 min",
    handoffStatus: "En route",
  },
  {
    id: "tr-12",
    requestId: "req-301",
    originHospitalId: "citizen",
    destinationHospitalId: "h-101",
    transportType: "Citizen-arranged",
    ambulanceId: "Self arrival",
    eta: "22 min",
    handoffStatus: "Waiting for hospital review",
  },
];

function getResource(resourceList, category) {
  return resourceList.find((item) => item.category === category);
}

function scoreHospital(hospital, diseaseCategory, urgencyLevel, preferredRadius, requestIndex) {
  const profile = diseaseCatalog[diseaseCategory];
  if (!profile) {
    return null;
  }

  const resource = getResource(hospital.resources, profile.resourceCategory);
  const ambulance = getResource(hospital.resources, "AMBULANCE");
  const specialtyFit = hospital.specialties.includes(profile.specialty);
  const activeCapacity = resource && resource.available > 0;

  if (!specialtyFit || !activeCapacity || hospital.distanceKm > preferredRadius) {
    return null;
  }

  const capacityScore = resource.available * 6;
  const specialtyScore = 30;
  const distanceScore = Math.max(0, 24 - hospital.distanceKm * 2);
  const urgencyScore = urgencyWeights[urgencyLevel] || 0;
  const ambulanceScore = profile.ambulancePreferred && ambulance?.available ? 8 : 0;
  const loadPenalty = hospital.emergencyStatus === "red" ? 10 : hospital.emergencyStatus === "amber" ? 4 : 0;
  const priorityTimePenalty = requestIndex * 3;
  const matchScore =
    specialtyScore +
    capacityScore +
    distanceScore +
    urgencyScore +
    ambulanceScore -
    loadPenalty -
    priorityTimePenalty;

  return {
    hospitalId: hospital.id,
    matchScore,
    distanceKm: hospital.distanceKm,
    specialtyFit,
    capacityFit: `${resource.available}/${resource.total} ${profile.resourceCategory.replace("_", " ").toLowerCase()}s`,
    estimatedResponseTime: `${Math.round(hospital.distanceKm * 4 + (hospital.emergencyStatus === "red" ? 12 : 6))} min`,
    recommendationReason: `${profile.specialty} ready, ${resource.available} ${profile.resourceCategory.replace("_", " ").toLowerCase()} slots live`,
  };
}

function rankHospitals(hospitals, diseaseCategory, urgencyLevel, preferredRadius, requestIndex = 0) {
  return hospitals
    .map((hospital) =>
      scoreHospital(hospital, diseaseCategory, urgencyLevel, preferredRadius, requestIndex),
    )
    .filter(Boolean)
    .sort((left, right) => right.matchScore - left.matchScore || left.distanceKm - right.distanceKm);
}

function formatStatus(status) {
  return status.replaceAll("_", " ").toLowerCase();
}

function formatTimestamp(timestamp) {
  return new Intl.DateTimeFormat("en-IN", {
    day: "2-digit",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
  }).format(new Date(timestamp));
}

function LandingHero({ onJump }) {
  return (
    <section className="hero-shell">
      <div className="hero-copy">
        <span className="eyebrow">Unified emergency and admission command</span>
        <h1>HospiConnect turns fragmented hospital capacity into a live care network.</h1>
        <p>
          Hospitals share real-time beds, doctors, ambulances, and equipment. Citizens
          describe what they need, and the platform routes them to the best available
          hospital based on specialty fit, urgency, capacity, and distance.
        </p>
        <div className="cta-row">
          <button className="primary-btn" onClick={() => onJump("citizen")}>
            Open citizen portal
          </button>
          <button className="ghost-btn" onClick={() => onJump("hospital")}>
            View hospital ops
          </button>
        </div>
      </div>
      <div className="hero-panel">
        <div className="hero-grid">
          <div>
            <strong>4</strong>
            <span>Hospitals broadcasting live capacity</span>
          </div>
          <div>
            <strong>2-sided</strong>
            <span>Citizen intake plus inter-hospital coordination</span>
          </div>
          <div>
            <strong>Priority aware</strong>
            <span>Triage severity wins before first-come fallback</span>
          </div>
          <div>
            <strong>Real-time</strong>
            <span>Recommendations shift as resource states change</span>
          </div>
        </div>
      </div>
    </section>
  );
}

function SummaryStrip({ requests, hospitals }) {
  const criticalCount = requests.filter((request) => request.urgencyLevel === "critical").length;
  const pendingCount = requests.filter((request) => request.status === "PENDING_HOSPITAL_REVIEW").length;
  const totalBeds = hospitals.reduce((sum, hospital) => {
    const icu = getResource(hospital.resources, "ICU_BED");
    return sum + (icu?.available || 0);
  }, 0);

  return (
    <section className="summary-strip">
      <article>
        <span>Live ICU beds</span>
        <strong>{totalBeds}</strong>
      </article>
      <article>
        <span>Citizen requests in flow</span>
        <strong>{requests.length}</strong>
      </article>
      <article>
        <span>Critical priority cases</span>
        <strong>{criticalCount}</strong>
      </article>
      <article>
        <span>Pending hospital reviews</span>
        <strong>{pendingCount}</strong>
      </article>
    </section>
  );
}

function CitizenPortal({
  citizens,
  hospitals,
  requests,
  draftRequest,
  setDraftRequest,
  activeCitizenId,
  setActiveCitizenId,
  recommendations,
  onSubmitRequest,
}) {
  const activeCitizen = citizens.find((citizen) => citizen.id === activeCitizenId) || citizens[0];
  const trackedRequests = requests.filter((request) => request.citizenId === activeCitizen.id);

  return (
    <section className="portal-grid" id="citizen">
      <div className="panel citizen-panel">
        <div className="section-heading">
          <div>
            <span className="eyebrow">Citizen Portal</span>
            <h2>Find the right hospital before reaching a dead end.</h2>
          </div>
          <select
            value={activeCitizen.id}
            onChange={(event) => setActiveCitizenId(event.target.value)}
            className="portal-select"
          >
            {citizens.map((citizen) => (
              <option key={citizen.id} value={citizen.id}>
                {citizen.name}
              </option>
            ))}
          </select>
        </div>

        <div className="card-stack">
          <article className="card tinted-card">
            <div className="card-head">
              <h3>{activeCitizen.name}</h3>
              <span>{activeCitizen.homeLocation}</span>
            </div>
            <p>
              Separate citizen login with request tracking, recommendation history, and
              admission updates without exposing hospital dashboards.
            </p>
          </article>

          <article className="card">
            <div className="card-head">
              <h3>Admission intake</h3>
              <span>Symptom-aware matching</span>
            </div>
            <div className="form-grid">
              <label>
                Disease or care need
                <select
                  value={draftRequest.diseaseCategory}
                  onChange={(event) =>
                    setDraftRequest((current) => ({
                      ...current,
                      diseaseCategory: event.target.value,
                      specialtyNeeded: diseaseCatalog[event.target.value].specialty,
                    }))
                  }
                >
                  {Object.entries(diseaseCatalog).map(([key, value]) => (
                    <option key={key} value={key}>
                      {value.label}
                    </option>
                  ))}
                </select>
              </label>
              <label>
                Urgency
                <select
                  value={draftRequest.urgencyLevel}
                  onChange={(event) =>
                    setDraftRequest((current) => ({
                      ...current,
                      urgencyLevel: event.target.value,
                    }))
                  }
                >
                  {Object.keys(urgencyWeights).map((level) => (
                    <option key={level} value={level}>
                      {level}
                    </option>
                  ))}
                </select>
              </label>
              <label>
                Current location
                <input
                  value={draftRequest.currentLocation}
                  onChange={(event) =>
                    setDraftRequest((current) => ({
                      ...current,
                      currentLocation: event.target.value,
                    }))
                  }
                />
              </label>
              <label>
                Preferred radius (km)
                <input
                  type="number"
                  min="2"
                  max="30"
                  value={draftRequest.preferredRadius}
                  onChange={(event) =>
                    setDraftRequest((current) => ({
                      ...current,
                      preferredRadius: Number(event.target.value),
                    }))
                  }
                />
              </label>
            </div>
            <label>
              Symptom summary
              <textarea
                rows="4"
                value={draftRequest.symptomSummary}
                onChange={(event) =>
                  setDraftRequest((current) => ({
                    ...current,
                    symptomSummary: event.target.value,
                  }))
                }
              />
            </label>
            <button className="primary-btn full-width" onClick={onSubmitRequest}>
              Submit admission request
            </button>
          </article>
        </div>
      </div>

      <div className="panel">
        <div className="section-heading">
          <div>
            <span className="eyebrow">Hospital Recommendations</span>
            <h2>Ranked by fit, distance, live capacity, and urgency.</h2>
          </div>
          <span className="chip">{recommendations.length} hospitals live</span>
        </div>
        <div className="card-stack">
          {recommendations.length ? (
            recommendations.map((match, index) => {
              const hospital = hospitals.find((item) => item.id === match.hospitalId);
              return (
                <article className="card recommendation-card" key={match.hospitalId}>
                  <div className="card-head">
                    <div>
                      <h3>
                        #{index + 1} {hospital.name}
                      </h3>
                      <span>
                        {hospital.city} · {hospital.type}
                      </span>
                    </div>
                    <span className={`status-badge status-${hospital.emergencyStatus}`}>
                      {hospital.emergencyStatus}
                    </span>
                  </div>
                  <div className="metric-row">
                    <div>
                      <strong>{match.matchScore}</strong>
                      <span>match score</span>
                    </div>
                    <div>
                      <strong>{match.distanceKm} km</strong>
                      <span>distance</span>
                    </div>
                    <div>
                      <strong>{match.estimatedResponseTime}</strong>
                      <span>estimated arrival</span>
                    </div>
                  </div>
                  <p>{match.recommendationReason}</p>
                  <p className="muted-copy">
                    Capacity: {match.capacityFit}. Specialties: {hospital.specialties.join(", ")}.
                  </p>
                </article>
              );
            })
          ) : (
            <article className="card">
              <h3>No live match inside the selected radius.</h3>
              <p>
                Increase radius or let the hospital network escalate to a transfer
                coordinator for a wider search.
              </p>
            </article>
          )}

          <article className="card">
            <div className="card-head">
              <h3>Request tracker</h3>
              <span>{trackedRequests.length} requests</span>
            </div>
            {trackedRequests.map((request) => (
              <div className="tracker-item" key={request.id}>
                <div>
                  <strong>{diseaseCatalog[request.diseaseCategory].label}</strong>
                  <span>
                    {request.specialtyNeeded} · {formatTimestamp(request.submittedAt)}
                  </span>
                </div>
                <span className="chip muted-chip">{formatStatus(request.status)}</span>
              </div>
            ))}
          </article>
        </div>
      </div>
    </section>
  );
}

function HospitalPortal({
  hospitals,
  requests,
  transfers,
  activeHospitalId,
  setActiveHospitalId,
  onReviewRequest,
}) {
  const hospital = hospitals.find((item) => item.id === activeHospitalId) || hospitals[0];
  const incomingRequests = requests.filter((request) => request.selectedHospitalId === hospital.id);
  const relatedTransfers = transfers.filter((transfer) => transfer.destinationHospitalId === hospital.id);

  return (
    <section className="portal-grid reverse-grid" id="hospital">
      <div className="panel">
        <div className="section-heading">
          <div>
            <span className="eyebrow">Hospital Operations Portal</span>
            <h2>Monitor capacity, citizen demand, and network transfers.</h2>
          </div>
          <select
            value={hospital.id}
            onChange={(event) => setActiveHospitalId(event.target.value)}
            className="portal-select"
          >
            {hospitals.map((item) => (
              <option key={item.id} value={item.id}>
                {item.name}
              </option>
            ))}
          </select>
        </div>

        <article className="card">
          <div className="card-head">
            <div>
              <h3>{hospital.name}</h3>
              <span>
                {hospital.type} · {hospital.city}
              </span>
            </div>
            <span className={`status-badge status-${hospital.emergencyStatus}`}>
              {hospital.emergencyStatus}
            </span>
          </div>
          <div className="resource-grid">
            {hospital.resources.map((resource) => (
              <div className="resource-tile" key={resource.category}>
                <strong>{resource.available}</strong>
                <span>{resource.category.replaceAll("_", " ")}</span>
                <small>of {resource.total} total</small>
              </div>
            ))}
          </div>
          <p className="muted-copy">
            Live specialties: {hospital.specialties.join(", ")}. Channels:{" "}
            {hospital.contactChannels.join(", ")}.
          </p>
        </article>

        <article className="card">
          <div className="card-head">
            <h3>Incoming citizen admissions</h3>
            <span>{incomingRequests.length} requests</span>
          </div>
          {incomingRequests.length ? (
            incomingRequests.map((request) => (
              <div className="queue-card" key={request.id}>
                <div>
                  <strong>{request.citizenName}</strong>
                  <span>
                    {request.specialtyNeeded} · {request.urgencyLevel} · {formatStatus(request.status)}
                  </span>
                </div>
                <p>{request.symptomSummary}</p>
                <div className="inline-actions">
                  <button
                    className="small-btn accept-btn"
                    onClick={() => onReviewRequest(request.id, "ACCEPTED")}
                  >
                    Accept
                  </button>
                  <button
                    className="small-btn redirect-btn"
                    onClick={() => onReviewRequest(request.id, "REDIRECTED")}
                  >
                    Redirect
                  </button>
                </div>
              </div>
            ))
          ) : (
            <p className="muted-copy">No citizen requests currently routed to this hospital.</p>
          )}
        </article>
      </div>

      <div className="panel">
        <div className="section-heading">
          <div>
            <span className="eyebrow">Network Coordination</span>
            <h2>Emergency requests and transfer command stay on the same platform.</h2>
          </div>
          <span className="chip">{hospital.emergencyRequests.length} emergency flows</span>
        </div>
        <div className="card-stack">
          <article className="card">
            <div className="card-head">
              <h3>Inter-hospital emergencies</h3>
              <span>Shared ops queue</span>
            </div>
            {hospital.emergencyRequests.length ? (
              hospital.emergencyRequests.map((request) => (
                <div className="tracker-item" key={request.id}>
                  <div>
                    <strong>{request.need}</strong>
                    <span>
                      {request.requestingHospital} · ETA {request.etaMinutes} min
                    </span>
                  </div>
                  <span className="chip muted-chip">{request.priority}</span>
                </div>
              ))
            ) : (
              <p className="muted-copy">No active emergency escalations for this hospital.</p>
            )}
          </article>

          <article className="card">
            <div className="card-head">
              <h3>Transfer management</h3>
              <span>{relatedTransfers.length} linked transfers</span>
            </div>
            {relatedTransfers.map((transfer) => (
              <div className="tracker-item" key={transfer.id}>
                <div>
                  <strong>{transfer.transportType}</strong>
                  <span>
                    {transfer.ambulanceId} · {transfer.eta}
                  </span>
                </div>
                <span className="chip muted-chip">{transfer.handoffStatus}</span>
              </div>
            ))}
          </article>

          <article className="card tinted-card">
            <div className="card-head">
              <h3>Manual override policy</h3>
              <span>For contention and downtime</span>
            </div>
            <p>
              If two citizen requests compete for the same scarce resource, the platform
              locks capacity for the higher triage case first, then falls back to request
              timestamp and the next-best hospital suggestion.
            </p>
          </article>
        </div>
      </div>
    </section>
  );
}

function AdminPanel({ requests, hospitals, transfers }) {
  const accepted = requests.filter((request) => request.status === "ACCEPTED").length;
  const redirected = requests.filter((request) => request.status === "REDIRECTED").length;

  return (
    <section className="admin-shell" id="admin">
      <div className="section-heading">
        <div>
          <span className="eyebrow">Platform Admin Portal</span>
          <h2>Proposal-ready overview, risk notes, and rollout metrics.</h2>
        </div>
      </div>
      <div className="admin-grid">
        <article className="card">
          <div className="card-head">
            <h3>Why this exists</h3>
            <span>Problem statement</span>
          </div>
          <p>
            The healthcare ecosystem operates in silos. Beds, doctors, ambulances, and
            critical equipment stay trapped inside disconnected hospital systems, while
            citizens make calls blindly during emergencies.
          </p>
        </article>
        <article className="card">
          <div className="card-head">
            <h3>Stakeholders</h3>
            <span>Citizen + hospital + admin</span>
          </div>
          <p>
            Citizens submit pre-admission requests. Hospitals broadcast capacity and review
            requests. Platform admins monitor fairness, service health, and cross-network
            coordination rules.
          </p>
        </article>
        <article className="card">
          <div className="card-head">
            <h3>Impact metrics</h3>
            <span>Demo KPIs</span>
          </div>
          <div className="metric-row">
            <div>
              <strong>{accepted}</strong>
              <span>accepted citizen requests</span>
            </div>
            <div>
              <strong>{redirected}</strong>
              <span>redirected without dead-end</span>
            </div>
            <div>
              <strong>{transfers.length}</strong>
              <span>transfer workflows tracked</span>
            </div>
          </div>
        </article>
        <article className="card">
          <div className="card-head">
            <h3>Architecture snapshot</h3>
            <span>Implementation direction</span>
          </div>
          <p>
            Next.js powers citizen, hospital, and admin surfaces. A matching service ranks
            hospitals from live resource data. Role-aware APIs handle admission requests,
            reviews, transfer status, and notifications.
          </p>
        </article>
        <article className="card">
          <div className="card-head">
            <h3>Privacy and risk</h3>
            <span>MVP boundaries</span>
          </div>
          <p>
            The MVP stops at recommendation and hospital review. It does not diagnose,
            process insurance, or directly edit hospital EHR records. Hospitals stay in
            control of final acceptance.
          </p>
        </article>
        <article className="card">
          <div className="card-head">
            <h3>Rollout phases</h3>
            <span>Phased roadmap</span>
          </div>
          <p>
            Phase 1 validates shared capacity visibility and citizen routing. Phase 2 adds
            stronger real-time sync and audit trails. Phase 3 can add insurance, deeper
            EHR integration, and ambulance orchestration.
          </p>
        </article>
      </div>
      <div className="footer-note">
        <span>{hospitals.length} hospitals live in this demo</span>
        <span>{requests.length} citizen requests simulated</span>
        <span>{transfers.length} active transfers</span>
      </div>
    </section>
  );
}

export default function Home() {
  const [citizens] = useState(citizensSeed);
  const [hospitals, setHospitals] = useState(hospitalsSeed);
  const [requests, setRequests] = useState(requestsSeed);
  const [transfers, setTransfers] = useState(transferSeed);
  const [activeCitizenId, setActiveCitizenId] = useState(citizensSeed[0].id);
  const [activeHospitalId, setActiveHospitalId] = useState(hospitalsSeed[0].id);
  const [draftRequest, setDraftRequest] = useState({
    diseaseCategory: "cardiac",
    urgencyLevel: "urgent",
    currentLocation: "Lajpat Nagar",
    preferredRadius: 12,
    symptomSummary: "Recurring chest discomfort and dizziness",
    specialtyNeeded: diseaseCatalog.cardiac.specialty,
  });

  const recommendations = useMemo(
    () =>
      rankHospitals(
        hospitals,
        draftRequest.diseaseCategory,
        draftRequest.urgencyLevel,
        draftRequest.preferredRadius,
        requests.length,
      ),
    [draftRequest, hospitals, requests.length],
  );

  function jumpTo(sectionId) {
    const section = document.getElementById(sectionId);
    section?.scrollIntoView({ behavior: "smooth", block: "start" });
  }

  function onSubmitRequest() {
    const citizen = citizens.find((item) => item.id === activeCitizenId) || citizens[0];
    const matches = rankHospitals(
      hospitals,
      draftRequest.diseaseCategory,
      draftRequest.urgencyLevel,
      draftRequest.preferredRadius,
      requests.length,
    );

    const topMatch = matches[0];
    const nextRequest = {
      id: `req-${400 + requests.length + 1}`,
      citizenId: citizen.id,
      citizenName: citizen.name,
      symptomSummary: draftRequest.symptomSummary,
      diseaseCategory: draftRequest.diseaseCategory,
      urgencyLevel: draftRequest.urgencyLevel,
      specialtyNeeded: diseaseCatalog[draftRequest.diseaseCategory].specialty,
      currentLocation: draftRequest.currentLocation,
      preferredRadius: draftRequest.preferredRadius,
      status: topMatch ? "PENDING_HOSPITAL_REVIEW" : "REDIRECTED",
      submittedAt: new Date().toISOString(),
      selectedHospitalId: topMatch?.hospitalId || null,
      recommendedHospitalIds: matches.map((match) => match.hospitalId),
    };

    setRequests((current) => [nextRequest, ...current]);

    if (topMatch) {
      setHospitals((current) =>
        current.map((hospital) => {
          if (hospital.id !== topMatch.hospitalId) {
            return hospital;
          }

          const category = diseaseCatalog[draftRequest.diseaseCategory].resourceCategory;
          return {
            ...hospital,
            incomingCitizenIds: [nextRequest.id, ...hospital.incomingCitizenIds],
            resources: hospital.resources.map((resource) =>
              resource.category === category
                ? { ...resource, available: Math.max(0, resource.available - 1) }
                : resource,
            ),
          };
        }),
      );

      setTransfers((current) => [
        {
          id: `tr-${40 + current.length + 1}`,
          requestId: nextRequest.id,
          originHospitalId: "citizen",
          destinationHospitalId: topMatch.hospitalId,
          transportType: diseaseCatalog[draftRequest.diseaseCategory].ambulancePreferred
            ? "Ambulance coordination requested"
            : "Citizen-arranged arrival",
          ambulanceId: diseaseCatalog[draftRequest.diseaseCategory].ambulancePreferred
            ? "Dispatch pending"
            : "Self arrival",
          eta: topMatch.estimatedResponseTime,
          handoffStatus: "Admission request submitted",
        },
        ...current,
      ]);
      setActiveHospitalId(topMatch.hospitalId);
    }

    setDraftRequest((current) => ({
      ...current,
      symptomSummary: "",
    }));
  }

  function onReviewRequest(requestId, nextStatus) {
    let updatedRequest;
    setRequests((current) =>
      current.map((request) => {
        if (request.id !== requestId) {
          return request;
        }

        updatedRequest = {
          ...request,
          status: nextStatus,
        };
        return updatedRequest;
      }),
    );

    if (!updatedRequest) {
      return;
    }

    setTransfers((current) =>
      current.map((transfer) =>
        transfer.requestId === requestId
          ? {
              ...transfer,
              handoffStatus:
                nextStatus === "ACCEPTED" ? "Hospital accepted patient" : "Redirecting to fallback",
            }
          : transfer,
      ),
    );

    if (nextStatus === "REDIRECTED") {
      const fallback = rankHospitals(
        hospitals.filter((hospital) => hospital.id !== updatedRequest.selectedHospitalId),
        updatedRequest.diseaseCategory,
        updatedRequest.urgencyLevel,
        updatedRequest.preferredRadius,
        0,
      )[0];

      if (!fallback) {
        return;
      }

      setRequests((current) =>
        current.map((request) =>
          request.id === requestId
            ? {
                ...request,
                selectedHospitalId: fallback.hospitalId,
                recommendedHospitalIds: [fallback.hospitalId, ...request.recommendedHospitalIds],
              }
            : request,
        ),
      );
      setActiveHospitalId(fallback.hospitalId);
    }
  }

  return (
    <main className="page-shell">
      <LandingHero onJump={jumpTo} />
      <SummaryStrip requests={requests} hospitals={hospitals} />
      <CitizenPortal
        citizens={citizens}
        hospitals={hospitals}
        requests={requests}
        draftRequest={draftRequest}
        setDraftRequest={setDraftRequest}
        activeCitizenId={activeCitizenId}
        setActiveCitizenId={setActiveCitizenId}
        recommendations={recommendations}
        onSubmitRequest={onSubmitRequest}
      />
      <HospitalPortal
        hospitals={hospitals}
        requests={requests}
        transfers={transfers}
        activeHospitalId={activeHospitalId}
        setActiveHospitalId={setActiveHospitalId}
        onReviewRequest={onReviewRequest}
      />
      <AdminPanel requests={requests} hospitals={hospitals} transfers={transfers} />
    </main>
  );
}
