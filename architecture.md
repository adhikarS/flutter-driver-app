# Waypoint Tracker - Architecture

## Overview
A minimal Flutter location tracking app with secure login and real-time GPS posting to a remote API.

## Core Features
1. **Login Screen**: Username/password authentication with local storage
2. **Tracker Screen**: Toggle-based location tracking with status display
3. **Location Service**: Foreground GPS tracking with 5-second API posting
4. **Persistent Auth**: Automatic login state management

## Technical Stack
- **Framework**: Flutter with Material Design 3
- **Location**: `location` package for GPS access
- **HTTP**: `http` package for API communication
- **Storage**: `shared_preferences` for user persistence
- **Theme**: Custom blue/green color scheme for navigation/tracking

## Architecture
```
├── models/
│   └── user.dart              # User data model
├── screens/
│   ├── login_screen.dart      # Username/password login
│   └── tracker_screen.dart    # Main tracking interface
├── services/
│   └── location_service.dart  # GPS & API service
├── main.dart                  # App entry & navigation
└── theme.dart                 # Material theme configuration
```

## Key Implementation Details
- **Location Tracking**: Combines location stream with 5-second timer fallback
- **API Integration**: Posts lat/lng to AWS endpoint with driver_id
- **Permission Handling**: Requests foreground location access on tracking start
- **Error Recovery**: Continues tracking on API failures with status updates
- **State Management**: Simple StatefulWidget approach for minimal complexity

## Security & Performance
- Local-only authentication (no external auth service)
- Foreground-only tracking (no background location)
- Automatic cleanup on logout and app termination
- Network error handling with retry mechanism