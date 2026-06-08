# Vault

Vault is a private Android media app tailored for personal/family use. It features IPTV streaming, Plex integration (both mock and future live), custom authentication, Kids profile filtering, and an OTA update mechanism.

## Architecture

* **Frontend:** Flutter
* **Backend:** Python + FastAPI
* **Database:** SQLite

## Setup Instructions

### Backend (Windows)

1. Navigate to the backend folder:
   ```cmd
   cd backend
   ```
2. Create and activate a Virtual Environment:
   ```cmd
   python -m venv .venv
   .\.venv\Scripts\activate
   ```
3. Install dependencies:
   ```cmd
   pip install -r requirements.txt
   ```
4. Copy the `.env.example` file to `.env` and fill the variables. The seed values are important for the first run.
5. Initialize Database and Start API:
   ```cmd
   python -m app.db.seed
   uvicorn app.main:app --reload
   ```

### Frontend

1. Navigate to `frontend/`.
2. Run `flutter pub get`
3. Connect your Android device or emulator.
4. Run `flutter run`.

## Notes on Features

* **Admin Seed:** Driven by `SEED_ADMIN_ON_FIRST_RUN`. Log in with default credentials and PLEASE change the password immediately.
* **Mock Plex:** When `MOCK_PLEX=true`, the backend generates dummy Plex library content to support development without connecting a real Plex server.
* **Kids Profile:** Accounts set as `kids` profile will only see content (Plex or IPTV) marked as kids-safe.
* **Suspension:** Suspended accounts are blocked entirely via backend dependency checking.
* **Migrating:** Since the project uses SQLite and relative paths, simply move this `Vault` folder to a new machine and re-run the backend virtual environment setup.

*This app is not for Google Play and will operate entirely on direct-APK distribution.*
