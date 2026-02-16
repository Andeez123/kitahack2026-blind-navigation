/* global google */
declare var google: any;

import React, { useState, useEffect, useRef, useCallback } from 'react';
import { GoogleGenAI, Modality, Type, FunctionDeclaration } from '@google/genai';
import { encode, decode, decodeAudioData, createBlob } from './utils/audio';
import { NavigationStatus, Location } from './types';

const FRAME_RATE = 2; 
const JPEG_QUALITY = 0.4;
const MODEL_NAME = 'gemini-2.5-flash-native-audio-preview-12-2025';
const TTS_MODEL_NAME = 'gemini-2.5-flash-preview-tts';
const AGENT_VOICE = 'Kore';

// Tool Definitions for Google Maps Integration
const searchPlaceTool: FunctionDeclaration = {
  name: 'search_place',
  parameters: {
    type: Type.OBJECT,
    description: 'Search for a place or business nearby using a text query.',
    properties: {
      query: { type: Type.STRING, description: 'The place name or category the user wants to find (e.g., "Starbucks", "Nearest hospital").' }
    },
    required: ['query'],
  },
};

const getDirectionsTool: FunctionDeclaration = {
  name: 'get_directions',
  parameters: {
    type: Type.OBJECT,
    description: 'Get walking directions between two points.',
    properties: {
      destination: { type: Type.STRING, description: 'The destination address or place ID.' }
    },
    required: ['destination'],
  },
};

const App: React.FC = () => {
  const [status, setStatus] = useState<NavigationStatus>(NavigationStatus.IDLE);
  const [location, setLocation] = useState<Location | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isLive, setIsLive] = useState(false);
  const [hasInteracted, setHasInteracted] = useState(false);
  const [lastInstruction, setLastInstruction] = useState<string>("Vision Guide is ready.");
  const [hazardDetected, setHazardDetected] = useState(false);
  const [detectedObstacles, setDetectedObstacles] = useState<string[]>([]);
  const [gpsActive, setGpsActive] = useState(false);
  const [routePath, setRoutePath] = useState<string | null>(null);
  const [backendDetections, setBackendDetections] = useState<any[]>([]);
  
  const [support, setSupport] = useState({ speech: false, mic: false, gps: false });

  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const audioContextInRef = useRef<AudioContext | null>(null);
  const audioContextOutRef = useRef<AudioContext | null>(null);
  const nextStartTimeRef = useRef<number>(0);
  const sourcesRef = useRef<Set<AudioBufferSourceNode>>(new Set());
  const sessionRef = useRef<any>(null);
  const frameIntervalRef = useRef<number | null>(null);
  const recognitionRef = useRef<any>(null);
  const watchIdRef = useRef<number | null>(null);
  const backendWsRef = useRef<WebSocket | null>(null);

  const isLiveRef = useRef(false);
  useEffect(() => {
    isLiveRef.current = isLive;
  }, [isLive]);

  useEffect(() => {
    const SpeechRecognition = (window as any).SpeechRecognition || (window as any).webkitRecognition || (window as any).webkitSpeechRecognition;
    setSupport(s => ({
      ...s,
      speech: !!SpeechRecognition,
      gps: !!navigator.geolocation
    }));
  }, []);

  const requestLocation = useCallback(() => {
    if (navigator.geolocation) {
      if (watchIdRef.current !== null) {
        navigator.geolocation.clearWatch(watchIdRef.current);
      }

      const options = { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 };
      const success = (pos: GeolocationPosition) => {
        setLocation({ latitude: pos.coords.latitude, longitude: pos.coords.longitude });
        setGpsActive(true);
      };
      const errCb = (err: GeolocationPositionError) => {
        setGpsActive(false);
        if (err.code === err.PERMISSION_DENIED) setError("GPS permission denied.");
      };

      navigator.geolocation.getCurrentPosition(success, errCb, options);
      watchIdRef.current = navigator.geolocation.watchPosition(success, errCb, options);
    }
  }, []);

  const playSystemSound = useCallback((type: 'alert' | 'activate') => {
    if (!audioContextOutRef.current) {
        audioContextOutRef.current = new (window.AudioContext || (window as any).webkitAudioContext)({ sampleRate: 24000 });
    }
    const ctx = audioContextOutRef.current;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    
    if (type === 'alert') {
        osc.type = 'square';
        osc.frequency.setValueAtTime(440, ctx.currentTime); 
        osc.frequency.exponentialRampToValueAtTime(880, ctx.currentTime + 0.1);
        gain.gain.setValueAtTime(0.2, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.2);
        setHazardDetected(true);
        setTimeout(() => setHazardDetected(false), 800);
    } else {
        osc.type = 'sine';
        osc.frequency.setValueAtTime(523.25, ctx.currentTime); 
        osc.frequency.exponentialRampToValueAtTime(783.99, ctx.currentTime + 0.2); 
        gain.gain.setValueAtTime(0.1, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.6);
    }

    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start();
    osc.stop(ctx.currentTime + (type === 'alert' ? 0.2 : 0.6));
  }, []);

  const speakWithAgentVoice = async (text: string) => {
    try {
const genAI = new GoogleGenAI({ apiKey: import.meta.env.VITE_GEMINI_API_KEY });
const response = await genAI.models.generateContent({
        model: TTS_MODEL_NAME,
        contents: [{ parts: [{ text }] }],
        config: {
          responseModalities: [Modality.AUDIO],
          speechConfig: { voiceConfig: { prebuiltVoiceConfig: { voiceName: AGENT_VOICE } } },
        },
      });
      const base64Audio = response.candidates?.[0]?.content?.parts?.[0]?.inlineData?.data;
      if (base64Audio) {
        const ctx = audioContextOutRef.current || new (window.AudioContext || (window as any).webkitAudioContext)({ sampleRate: 24000 });
        const audioBuffer = await decodeAudioData(decode(base64Audio), ctx, 24000, 1);
        const source = ctx.createBufferSource();
        source.buffer = audioBuffer;
        source.connect(ctx.destination);
        source.start();
      }
    } catch (e) {
      window.speechSynthesis.speak(new SpeechSynthesisUtterance(text));
    }
  };

  const handleSearchPlace = (query: string) => {
  return new Promise((resolve) => {
    if (typeof google === 'undefined') {
      resolve({ error: "Google Maps SDK not loaded yet." });
      return;
    }

    const service = new google.maps.places.PlacesService(document.createElement('div'));
    const request = {
      query,
      location: location ? new google.maps.LatLng(location.latitude, location.longitude) : undefined,
      radius: 5000
    };

    service.textSearch(request, (results: any, status: any) => {
      if (status === google.maps.places.PlacesServiceStatus.OK && results) {
        resolve(results.slice(0, 3).map((r: any) => ({
          name: r.name,
          address: r.formatted_address,
          place_id: r.place_id
        })));
      } else {
        resolve({ error: "No places found nearby." });
      }
    });
  });
};

const handleGetDirections = (destination: string) => {
  return new Promise((resolve) => {
    if (typeof google === 'undefined') {
      resolve({ error: "SDK not loaded." });
      return;
    }

    const directionsService = new google.maps.DirectionsService();
    const request = {
      origin: location ? new google.maps.LatLng(location.latitude, location.longitude) : '',
      destination: destination,
      travelMode: google.maps.TravelMode.WALKING
    };

    directionsService.route(request, (result: any, status: any) => {
      if (status === google.maps.DirectionsStatus.OK && result) {
        const route = result.routes[0];
        setRoutePath(route.overview_polyline); // Store encoded polyline for the map

        const leg = route.legs[0];
        resolve({
          steps: leg.steps.map((s: any) => s.instructions.replace(/<[^>]*>?/gm, '')),
          total_distance: leg.distance?.text,
          total_duration: leg.duration?.text
        });
      } else {
        resolve({ error: "Could not find a walking route." });
      }
    });
  });
};

  const stopSession = useCallback(() => {
    if (!isLiveRef.current) return;
    playSystemSound('activate');
    setIsLive(false);
    isLiveRef.current = false;
    setStatus(NavigationStatus.IDLE);
    setLastInstruction("Vision Guide Standby.");
    setDetectedObstacles([]);
    setRoutePath(null);
    nextStartTimeRef.current = 0;
    if (sessionRef.current) sessionRef.current.close?.();
    if (backendWsRef.current) {
        backendWsRef.current.close();
        backendWsRef.current = null;
    }
    if (frameIntervalRef.current) window.clearInterval(frameIntervalRef.current);
    sourcesRef.current.forEach(s => { try { s.stop(); } catch(e) {} });
    sourcesRef.current.clear();
    if (videoRef.current?.srcObject) (videoRef.current.srcObject as MediaStream).getTracks().forEach(t => t.stop());
    speakWithAgentVoice("Navigation disconnected. I am back on standby.");
  }, [playSystemSound]);

  const startSession = useCallback(async () => {
    if (isLiveRef.current) return;
    playSystemSound('activate');
    requestLocation();

    try {
      setStatus(NavigationStatus.INITIALIZING);
      setError(null);
      if (recognitionRef.current) recognitionRef.current.stop();

      const stream = await navigator.mediaDevices.getUserMedia({ 
        audio: true, 
        video: { facingMode: { ideal: 'environment' }, width: { ideal: 640 }, height: { ideal: 480 } } 
      });

      if (videoRef.current) videoRef.current.srcObject = stream;
      
       const genAI = new GoogleGenAI({ apiKey: import.meta.env.VITE_GEMINI_API_KEY });
      const sessionPromise = genAI.live.connect({
        model: MODEL_NAME,
        callbacks: {
          onopen: () => {
            setIsLive(true);
            isLiveRef.current = true;
            setStatus(NavigationStatus.ACTIVE);
            sessionPromise.then((s: any) => s.sendRealtimeInput({ text: "Agent: Be brief and immediate. Start by asking 'Where would you like to go today?' and immediately use the tools if a destination is mentioned." }));

            const audioIn = audioContextInRef.current || new (window.AudioContext || (window as any).webkitAudioContext)({ sampleRate: 16000 });
            audioContextInRef.current = audioIn;
            const source = audioIn.createMediaStreamSource(stream);
            const scriptProcessor = audioIn.createScriptProcessor(4096, 1, 1);
            scriptProcessor.onaudioprocess = (e) => {
              if (isLiveRef.current) {
                const data = e.inputBuffer.getChannelData(0);
                sessionPromise.then(s => s.sendRealtimeInput({ media: createBlob(data) }));
              }
            };
            source.connect(scriptProcessor);
            scriptProcessor.connect(audioIn.destination);

            // Connect to backend detection service
            const backendWs = new WebSocket('ws://localhost:8000/ws/vision');
            backendWs.onopen = () => console.log("Connected to backend vision service");
            backendWs.onmessage = (e) => {
                const data = JSON.parse(e.data);
                if (data.status === 'success') {
                    setBackendDetections(data.detections || []);
                    if (data.hazard) {
                        playSystemSound('alert');
                        setHazardDetected(true);
                        setTimeout(() => setHazardDetected(false), 500);
                    }
                }
            };
            backendWs.onerror = (e) => console.error("Backend WebSocket error", e);
            backendWsRef.current = backendWs;

            frameIntervalRef.current = window.setInterval(() => {
              if (videoRef.current && canvasRef.current && isLiveRef.current) {
                const ctx = canvasRef.current.getContext('2d');
                if (ctx && videoRef.current.videoWidth > 0) {
                  canvasRef.current.width = 320; canvasRef.current.height = 240;
                  ctx.drawImage(videoRef.current, 0, 0, 320, 240);
                  canvasRef.current.toBlob(b => {
                    if (b) {
                      const reader = new FileReader();
                      reader.onloadend = () => {
                        const base64 = (reader.result as string).split(',')[1];
                        // Send to Gemini
                        sessionPromise.then(s => s.sendRealtimeInput({ media: { data: base64, mimeType: 'image/jpeg' } }));
                        
                        // Send to Backend Detection Service
                        if (backendWsRef.current && backendWsRef.current.readyState === WebSocket.OPEN) {
                            backendWsRef.current.send(JSON.stringify({ image: base64 }));
                        }
                      };
                      reader.readAsDataURL(b);
                    }
                  }, 'image/jpeg', JPEG_QUALITY);
                }
              }
            }, 1000 / FRAME_RATE);
          },
          onmessage: async (msg) => {
            if (msg.serverContent?.inputTranscription?.text) {
              const transcript = msg.serverContent.inputTranscription.text.toLowerCase().trim();
              if (/(stop|quit|end|cancel|disconnect|finish)/.test(transcript)) {
                stopSession();
                return;
              }
            }

            if (msg.toolCall?.functionCalls) {
              for (const fc of msg.toolCall.functionCalls) {
                if (!fc.args) continue;
                let res = fc.name === 'search_place' ? await handleSearchPlace(fc.args.query as string) : await handleGetDirections(fc.args.destination as string);
                sessionPromise.then(s => s.sendToolResponse({ functionResponses: { id: fc.id, name: fc.name, response: { result: res } } }));
              }
            }

            const base64 = msg.serverContent?.modelTurn?.parts?.[0]?.inlineData?.data;
            if (base64 && isLiveRef.current) {
              const ctx = audioContextOutRef.current || new (window.AudioContext || (window as any).webkitAudioContext)({ sampleRate: 24000 });
              audioContextOutRef.current = ctx;
              nextStartTimeRef.current = Math.max(nextStartTimeRef.current, ctx.currentTime);
              const buf = await decodeAudioData(decode(base64), ctx, 24000, 1);
              const src = ctx.createBufferSource();
              src.buffer = buf; src.connect(ctx.destination);
              src.onended = () => sourcesRef.current.delete(src);
              src.start(nextStartTimeRef.current);
              nextStartTimeRef.current += buf.duration;
              sourcesRef.current.add(src);
            }

            const text = msg.serverContent?.modelTurn?.parts?.find(p => p.text)?.text || "";
            if (text && isLiveRef.current) {
              setLastInstruction(text);
              if (/(stop|watch out|careful|hazard|danger|pole|person|stair|curb)/i.test(text)) playSystemSound('alert');
            }
          },
          onerror: () => stopSession(),
          onclose: () => stopSession()
        },
        config: {
          responseModalities: [Modality.AUDIO],
          speechConfig: { voiceConfig: { prebuiltVoiceConfig: { voiceName: AGENT_VOICE } } },
          tools: [{ functionDeclarations: [searchPlaceTool, getDirectionsTool] }],
          inputAudioTranscription: {}, 
          systemInstruction: `You are VisionGuide AI, a real-time navigation expert for the blind.
          1. BE CONCISE. Do not use long sentences.
          2. IMMEDIATELY start by asking: "Where would you like to go today?"
          3. Use search_place and get_directions tools as soon as possible.
          4. When navigating, provide small, punchy walking instructions (e.g., "Left in 10 steps", "Stay straight").
          5. PRIORITIZE SAFETY. If you see hazards (poles, drops, people), say "STOP" or "WATCH OUT" immediately.
          6. User location: ${location ? `${location.latitude},${location.longitude}` : 'Unknown'}.`,
        }
      });
      sessionRef.current = await sessionPromise;
    } catch (err: any) {
      setError(err.message);
      setStatus(NavigationStatus.ERROR);
      stopSession();
    }
  }, [location, playSystemSound, stopSession, requestLocation]);

  const handleEnableVoice = async () => {
    setError(null);
    try {
      playSystemSound('activate');
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      stream.getTracks().forEach(t => t.stop());
      requestLocation();
      setHasInteracted(true);
      speakWithAgentVoice("Vision Guide ready. Say Start to begin.");

      const SpeechRecognition = (window as any).SpeechRecognition || (window as any).webkitRecognition || (window as any).webkitSpeechRecognition;
      if (SpeechRecognition) {
        const recognition = new SpeechRecognition();
        recognition.continuous = true;
        recognition.lang = 'en-US';
        recognition.onresult = (e: any) => {
          const t = e.results[e.results.length - 1][0].transcript.toLowerCase();
          if (t.includes("start") || t.includes("hi") || t.includes("hello")) {
            recognition.stop();
            startSession();
          }
        };
        recognition.onend = () => { if (!isLiveRef.current) try { recognition.start(); } catch(e) {} };
        recognitionRef.current = recognition;
        recognition.start();
      }
    } catch (e) { setError("Microphone required."); }
  };

  return (
    <div className="flex flex-col h-screen bg-black text-white overflow-hidden font-sans select-none">
      <div className={`absolute top-4 right-4 w-24 h-32 z-50 transition-opacity duration-500 ${isLive ? 'opacity-100' : 'opacity-0'}`}>
        <video ref={videoRef} autoPlay playsInline muted 
          className="w-full h-full object-cover rounded-xl border-2 border-zinc-800"
        />
        {/* Detection Overlay on Thumbnail */}
        <div className="absolute inset-0 pointer-events-none overflow-hidden rounded-xl">
          {backendDetections.map((det, i) => {
            const [x1, y1, x2, y2] = det.box;
            // Map 320x240 (backend) to video thumbnail dimensions
            const left = (x1 / 320) * 100;
            const top = (y1 / 240) * 100;
            const width = ((x2 - x1) / 320) * 100;
            const height = ((y2 - y1) / 240) * 100;
            
            return (
              <div key={i} style={{
                position: 'absolute',
                left: `${left}%`,
                top: `${top}%`,
                width: `${width}%`,
                height: `${height}%`,
                border: '1px solid #22c55e',
                backgroundColor: 'rgba(34, 197, 94, 0.2)'
              }}>
                <span className="text-[6px] text-white bg-green-500 px-0.5 leading-none absolute -top-1 left-0">
                  {det.label}
                </span>
              </div>
            );
          })}
        </div>
      </div>
      <canvas ref={canvasRef} className="hidden" />

      {!hasInteracted ? (
        <button onClick={handleEnableVoice} className="flex-1 flex flex-col items-center justify-center p-8 bg-zinc-950">
          <div className="w-56 h-56 rounded-full border-[8px] border-yellow-400 flex items-center justify-center mb-12">
            <div className="w-20 h-20 bg-yellow-400 rounded-full animate-pulse shadow-[0_0_40px_#facc15]" />
          </div>
          <h1 className="text-5xl font-black text-yellow-400 uppercase tracking-tighter mb-4">VisionGuide</h1>
          <p className="bg-zinc-900 px-6 py-3 rounded-full border border-zinc-800 font-bold uppercase tracking-widest text-sm">Tap to Activate</p>
        </button>
      ) : !isLive ? (
        <div className="flex flex-col items-center justify-between h-full p-8 py-20 bg-gradient-to-b from-black to-zinc-950">
          <div className="text-center">
            <h1 className="text-4xl font-black text-yellow-400 uppercase mb-4">Standby</h1>
            <div className="flex flex-col items-center gap-2">
              <div className="flex items-center gap-3 bg-zinc-900/50 px-6 py-2 rounded-full border border-zinc-800">
                 <div className="w-3 h-3 bg-green-500 rounded-full animate-pulse shadow-[0_0_10px_#22c55e]" />
                 <p className="text-zinc-400 font-bold uppercase tracking-[0.2em] text-xs">Listening for "Start"</p>
              </div>
              <p className={`text-[10px] font-black uppercase tracking-widest ${gpsActive ? 'text-green-500' : 'text-red-500'}`}>GPS: {gpsActive ? 'ACTIVE' : 'NO SIGNAL'}</p>
            </div>
          </div>
          <button onClick={startSession} className="w-72 h-72 rounded-full flex items-center justify-center bg-zinc-900 border-2 border-zinc-800 shadow-2xl active:scale-95 transition-all">
             <span className="text-sm font-black uppercase tracking-[0.3em]">Ready</span>
          </button>
          {error && <p className="text-red-400 text-xs font-bold uppercase bg-red-950/20 p-3 rounded-xl">{error}</p>}
        </div>
      ) : (
        <div className="flex flex-col h-full">
          {/* Main Content Area focused on Map and Alerting */}
          <div className="relative flex-1 bg-zinc-900 overflow-hidden">
            {location ? (
              <img className="w-full h-full object-cover grayscale invert contrast-125 opacity-90" 
                src={`https://maps.googleapis.com/maps/api/staticmap?center=${location.latitude},${location.longitude}&zoom=19&size=640x640&scale=2&maptype=roadmap&key=${import.meta.env.VITE_GOOGLE_MAPS_API_KEY}&style=feature:all|element:labels|invert_lightness:true${routePath ? `&path=weight:5|color:0xFAFF00|enc:${routePath}` : ''}`} 
                alt="Map" />
            ) : <div className="w-full h-full flex items-center justify-center font-black uppercase text-zinc-700">Searching GPS...</div>}
            
            {/* User Pointer */}
            <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
              <div className="w-6 h-6 bg-yellow-400 rounded-full border-2 border-white animate-pulse shadow-[0_0_15px_rgba(250,204,21,0.5)]" />
            </div>

            {/* Visual Obstacle/Hazard Overlay */}
            {hazardDetected && (
              <div className="absolute inset-0 bg-red-600/60 flex items-center justify-center z-50">
                <div className="bg-red-600 border-4 border-white px-10 py-6 shadow-2xl rounded-2xl animate-bounce">
                  <span className="text-8xl font-black text-white uppercase italic">STOP</span>
                </div>
              </div>
            )}
          </div>

          {/* Emergency Stop/Disconnect Button - Minimized and Centered */}
          <div className="p-6 bg-black border-t-2 border-zinc-900 flex justify-center">
            <button 
              onClick={stopSession} 
              className="w-2/3 max-w-[240px] py-4 bg-red-600 rounded-2xl font-black text-white uppercase tracking-widest text-lg active:scale-95 shadow-[0_4px_0_rgb(153,27,27)] active:shadow-none active:translate-y-1 transition-all"
              aria-label="Stop Session"
            >
              STOP
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default App;
