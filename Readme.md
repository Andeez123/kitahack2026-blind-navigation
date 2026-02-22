# AI Vision Guide with Real-time obstacle detection

### Submission for Kitahack 2026 by team fluffly bears

### Contributors
- Andrew Chong
- Leah Liew
- Cheong Li Hua
- Lee Yun Ling

## Key Features
- Real-time object detection and depth estimation
- Text-to-speech navigation instructions
- Google Maps integration for navigation
- Hazard detection and alerts

## Tech Stack
- React
- FastAPI
- Google Gemini API
- YOLOv8
- MiDaS

## Installation & Setup

### Backend
```bash
cd backend
python -m venv venv

Activate environment:
**Window:** venv\Scripts\activate
**IOS:** source venv/bin/activate

pip install -r requirements.txt
```

### Frontend
```bash
cd frontend
cp .env_example .env (insert your API keys here)
npm install
```

## Usage

### Backend
```bash
cd backend
python main.py
```

### Frontend
```bash
cd frontend
npm run dev
``` 
