
export interface Location {
  latitude: number;
  longitude: number;
}

export enum NavigationStatus {
  IDLE = 'IDLE',
  INITIALIZING = 'INITIALIZING',
  ACTIVE = 'ACTIVE',
  ERROR = 'ERROR'
}

export interface NavigationStep {
  instruction: string;
  distance: string;
}
