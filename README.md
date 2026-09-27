# 🚑 HospiConnect – Emergency Healthcare Coordination Platform

**Connecting Hospitals. Saving Lives.**

HospiConnect is a real-time healthcare coordination platform connecting **patients, ASHA/health workers, ambulances, and hospitals** to reduce emergency delays, improve referrals, and coordinate medical resources.

---

## 📌 Overview

In emergency and rural healthcare situations, patients may lose critical time searching for facilities with the right resources. Hospitals often have fragmented information, while ambulances and healthcare workers need better coordination.

HospiConnect addresses these challenges through:

* Patient → Hospital connection through an SOS emergency system
* ASHA/Health Worker → PHC/Hospital coordination and intelligent referrals
* Hospital → Hospital coordination for resource sharing and patient transfers
* Ambulance → Real-time dispatch, status updates, and tracking
* Continuity of patient information across the healthcare journey

---

## 🔗 Project Repositories

### 🌐 Hospital Dashboard (Web)

👉 https://github.com/ved-2/Prayatna-3.0.git

* Manage ICU beds and hospital resources
* View incoming emergency patients and referrals
* Monitor ambulance ETA and emergency status
* Manage doctor availability and patient queues
* Coordinate patient transfers
* Request resources from connected hospitals
* View reports and analytics

### 📱 Citizen App (Mobile)

👉 https://github.com/ved-2/Citizen-Mobile.git

* One-tap SOS emergency request
* Share location and emergency information
* View nearby and appropriate hospitals
* Track ambulances in real time
* Receive emergency status updates

### 🚑 Ambulance App (Mobile)

👉 https://github.com/ved-2/hospi-connect/tree/ambulance

**Branch:** `ambulance`

* Receive emergency requests
* Share live GPS location
* Update ambulance status
* Manage Enroute / Arrived / Completed workflow
* Coordinate patient pickup and hospital arrival

### 👩‍⚕️ ASHA / Health Worker App (Mobile)

👉 https://github.com/ved-2/Asha-Mobile.git

* Register patients in the field
* Capture symptoms, vitals, and screening information
* Conduct initial health screening
* Create and manage referrals
* Receive alerts and referral updates
* Track patient follow-ups
* Access village/area-level patient overviews
* Support escalation of high-risk cases to appropriate facilities

---

## ⚙️ Tech Stack

### Frontend

* Flutter — Mobile applications
* Web dashboard for hospital operations

### Backend

* Firebase Cloud Functions

### Database and Real-Time Services

* Firebase Authentication
* Cloud Firestore
* Real-time synchronization

### AI

* Google Gemini
* AI-assisted symptom analysis and decision support

---

## 🧠 Key Features

* 🚨 SOS Emergency System
* 👩‍⚕️ ASHA / Health Worker Patient Registration and Screening
* 🏥 Intelligent Hospital and Facility Selection
* 🔄 Intelligent Referral Coordination
* 🚑 Real-Time Ambulance Tracking
* 🏥 Hospital Resource and ICU Management
* 🔁 Hospital-to-Hospital Patient Transfer
* 🤝 Inter-Hospital Resource Requests
* 👨‍⚕️ Doctor Availability and Patient Queue Management
* 📋 Digital Patient Information and Referral Records
* 🔔 Notifications and Emergency Alerts
* 📊 Hospital Reports and Analytics
* 🤖 AI-Assisted Symptom Analysis

---

## 🔄 System Workflow

### Emergency Workflow

1. Patient triggers SOS.
2. The system captures location and emergency information.
3. AI-assisted analysis supports urgency classification and identification of relevant care needs.
4. The backend evaluates suitable hospitals based on required capabilities and available operational information.
5. An ambulance is requested and coordinated.
6. The patient can track ambulance status in real time.
7. The receiving hospital receives an incoming emergency alert and relevant patient information.

### Rural / Primary Healthcare Workflow

1. An ASHA worker or healthcare worker registers the patient.
2. Symptoms, vitals, screening details, and relevant medical history are recorded.
3. The system identifies the required level of care and referral needs.
4. Suitable facilities are evaluated using severity, capabilities, diagnostic availability, specialist availability, distance, and operational availability.
5. Authorized healthcare staff review and confirm the referral.
6. The receiving facility accepts or rejects the referral.
7. Patient information and referral status remain available throughout the care journey.
8. Follow-ups and subsequent escalations are recorded.

---

## 🏥 Healthcare Coordination Flow

**Patient → ASHA / Health Worker → Sub-Centre → PHC → Rural Hospital → District Hospital → Specialist**

HospiConnect supports continuity of:

* Patient information
* Medical history
* Symptoms and vitals
* Diagnostic reports
* X-rays and medical images
* Referrals
* Treatment information
* Emergency information
* Follow-up records

---

## 🎯 Intended Impact

* Faster emergency coordination
* More informed facility selection
* Reduced avoidable referral and transfer delays
* Better visibility of hospital resources
* Improved ambulance coordination
* Stronger continuity of patient information
* Better support for healthcare workers in underserved areas

---

## 🚀 Future Scope

* Government healthcare and approved public-health system integration
* ABDM / FHIR-based interoperability where applicable
* Multi-district and multi-city deployment
* Teleconsultation and specialist access
* Voice-based healthcare workflows
* Advanced analytics and capacity planning
* AI-assisted diagnostic support with appropriate clinical validation

---

## 👨‍💻 Team

**Team Name: Neural Ninjas**

---

## 📌 Note

HospiConnect is modularized into multiple repositories so that citizen, healthcare-worker, ambulance, and hospital components can evolve independently.

The platform is designed to **strengthen existing healthcare infrastructure and support healthcare professionals**, not replace doctors, hospitals, or official emergency services.

All components are linked above for easy access.
