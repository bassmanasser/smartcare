# SmartCare

SmartCare is a Flutter healthcare app for patient monitoring, hospital intake,
care-team collaboration, QR-based patient lookup, and role-based workflows.

## Main Roles

- Patient: live vitals, QR code, reports, medications, alerts, AI assistant,
  profile updates, language and theme settings.
- Parent / family: linked patient follow-up and parent profile settings.
- Doctor: assigned patients, QR scan, requests, appointments, and notes.
- Nurse: hospital workflow dashboard and patient scanning.
- Staff / triage: scan patient QR codes, view hospital patients, and assign
  patients to approved doctors.
- Hospital admin: hospital setup, staff approvals, departments, dispatch
  dashboard, and emergency queue.

## Key Features

- Firebase Authentication and Cloud Firestore data storage.
- Arabic / English localization controlled from app settings and welcome flow.
- Patient Settings entry for updating personal, emergency, and medical data.
- QR patient intake for staff, nurses, and doctors.
- Staff patient list with doctor assignment from the same hospital.
- Firestore rules for role-based access to users, patient clinical data,
  care links, dispatch cases, and institution patient records.
- BLE vitals ingestion, alerts, risk assessment, and dispatch recommendation
  logic.

## Project Structure

- `lib/screens`: role-based screens and app flows.
- `lib/services`: Firebase, BLE, reports, alerts, dispatch, and health services.
- `lib/models`: patient, doctor, alert, vitals, risk, and workflow models.
- `lib/providers/app_state.dart`: shared app state, locale, theme, vitals, and
  dispatch state.
- `lib/utils/localization.dart`: in-app translation map.
- `firestore.rules`: Firestore security rules.
- `functions`: Firebase Cloud Functions project.

## Setup

1. Install Flutter and Firebase CLI.
2. Run `flutter pub get`.
3. Check Firebase config files:
   - `lib/firebase_options.dart`
   - `android/app/google-services.json`
   - `firebase.json`
4. Run the app:

```bash
flutter run
```

## Firebase Rules

Deploy Firestore rules after reviewing project IDs and test data:

```bash
firebase deploy --only firestore:rules
```

The current rules allow:

- Patients to update their own profile data while preserving protected role and
  institution fields.
- Approved hospital staff to read patient profiles during QR intake.
- Approved staff to update only routing/intake fields when assigning scanned
  patients to a hospital workflow or doctor.
- Doctors, nurses, staff, admins, patients, and linked parents to read clinical
  subcollections only when allowed by role and relationship.

## Notes

Some older screens still contain hard-coded English labels. The shared
localization infrastructure is available, so new UI should use
`AppLocalizations.of(context).translate('key')` and add keys in
`lib/utils/localization.dart`.
