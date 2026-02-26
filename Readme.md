# NavAssist (AI Vision Guide with Real-time obstacle detection)

### Submission for Kitahack 2026 by team fluffly bears

### Contributors
- Andrew Chong
- Leah Liew
- Cheong Li Hua
- Lee Yun Ling

## Project Overview
### Problem Statement
Despite 68,665 registered visually impaired individuals in Malaysia in 2024, existing mobility aids—such as canes, guide dogs, and GPS-based navigation apps—remain limited in accessibility and functionality. Current digital navigation solutions lack full voice-controlled destination input, cohesive voice-assisted navigation, and real-time obstacle detection with depth perception. As a result, totally blind users are still required to manually interact with applications and are left without adequate protection against immediate environmental hazards, creating a critical gap in safe, independent mobility.

### SDG Alignment
Our solution and product relates to SDG 10, specifically Target 10.2 of reduced inequalities. Our project aims to promote social inclusion, by improving the capability of the visually impaired to be independent and self-sufficient, reducing discrimination, and improving social and economic inclusion.

### Our Solution
Our solution is an AI-powered navigation system that uses computer vision and natural language processing to provide real-time navigation instructions to visually impaired users. The system uses YOLOv8 for object detection and depth estimation, and Google Gemini API for natural language processing. The system also uses Google Maps API for navigation and hazard detection.

## Key Features
- Real-time object detection and depth estimation
- Speech-to-text destination input
- Text-to-speech navigation instructions
- Google Maps integration for navigation
- Hazard detection and alerts

## Overview of Technologies Used
### Google Technologies
- **Google Gemini API**: Powers the voice interaction, natural language understanding, and decision-making (Live API + TTS).
- **Google Maps Platform**: 
  - **JavaScript API**: For rendering maps and calculating distances.
  - **Places API**: For location search and discovery.
  - **Directions API**: For basic route planning.
- **Google Cloud Run**: Hosts the high-performance Python vision processing backend.

### Other Technologies
- **React + Vite**: Frontend framework.
- **FastAPI**: Asynchronous Python framework for handling real-time WebSocket communication.
- **YOLOv8 (Ultralytics)**: State-of-the-art real-time object detection.
- **MiDaS (Intel ISL)**: Deep-learning based monocular depth estimation.
- **OpenRouteService**: Provides granular walking paths and turn-by-turn navigation data.
- **Vercel**: Deployment platform for the frontend.

## Implementation Details and Innovation
### System Architecture
<img width="1360" height="618" alt="kitahack2026 (1)" src="https://github.com/user-attachments/assets/0ac5bd74-255b-460f-bb25-f28e27a8d378" />

### Workflow
1. **Initiation**: User grants camera, microphone, and GPS permissions.
2. **Streaming**: Real-time camera frames are sent via WebSockets to the Python backend.
3. **Detection**: The backend analyzes frames to identify obstacles and their distance (proximity).
4. **Hazard Alerts**: If a hazard is detected within "Close" range, the app plays an immediate alert sound.
5. **Voice Input**: User gives a destination command (e.g., "Take me to the nearest clinic").
6. **Navigation**: Gemini processes the request, calculates the route using OpenRouteService, and provides real-time turn-by-turn voice guidance.

## Challenges Faced
Deployment of the backend proved to be a huge headache, with 2 models to deploy on cloud services, multiple dependencies like OpenCV, and Pytorch had to be installed on a docker container, which took a long time. Initial deployment builds took a super long time as it was attempting to build the frontend and the node modules. We did not realize this error at first, which meant google cloud was trying to build 2.2GB worth of files, excluding node modules and frontend shrank the build size to around 2KB, which made the build process faster. 

## Installation & Setup

### Backend
```bash
cd backend
python -m venv venv

Activate environment:
**Window:** venv\Scripts\activate
**Mac OS:** source venv/bin/activate

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

## Future Roadmap
- Multi-language support (Bahasa Malaysia focus).
- Haptic feedback patterns for obstacle distance.
- Precise obstacle description and warning.
- Mobile native application for iOS and Android.
