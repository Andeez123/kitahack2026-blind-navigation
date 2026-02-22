# AI Vision Guide with Real-time obstacle detection

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
- Google Gemini API
- Google Maps API
- Google Cloud Run

### Other Technologies
- React
- FastAPI
- YOLOv8
- MiDaS

## Implementation Details and Innovation
### System Architecture

### Workflow

## Challenges Faced

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

## Future Roadmap