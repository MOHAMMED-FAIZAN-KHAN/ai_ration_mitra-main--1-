# FPS Locator - Google Maps Integration Setup Guide

## Overview
The FPS Locator feature has been successfully integrated with Google Maps and location services. Users can now:
- View their current location on the map
- See all nearby Fair Price Shops with markers
- Search for FPS shops by name or area
- View distance to each shop
- Get directions and call shops
- Filter shops within 30km radius

## Prerequisites
- Google Maps API Key
- Android and iOS configuration

## Setup Instructions

### 1. Get Google Maps API Key

#### For Android:
1. Visit [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project
3. Enable the following APIs:
   - Maps SDK for Android
   - Geocoding API
   - Distance Matrix API
4. Create an API key (Credentials > Create Credentials > API Key)
5. Add your release and debug signing certificate SHA-1 fingerprints

#### For iOS:
1. Follow the same steps in Google Cloud Console
2. Create an API key for iOS
3. Set up app restrictions if needed

### 2. Update Configuration Files

#### Android Configuration
Update `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
  android:name="com.google.android.geo.API_KEY"
  android:value="YOUR_ACTUAL_GOOGLE_MAPS_API_KEY_HERE" />
```

#### iOS Configuration
Update `ios/Runner/Info.plist`:
```xml
<key>GoogleMapsAPIKey</key>
<string>YOUR_ACTUAL_GOOGLE_MAPS_API_KEY_HERE</string>
```

### 3. Location Permissions

**Android** - Already configured in `AndroidManifest.xml`:
- `android.permission.ACCESS_FINE_LOCATION`
- `android.permission.ACCESS_COARSE_LOCATION`

**iOS** - Already configured in `Info.plist`:
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`

Users will be prompted to grant location access when they first use the FPS Locator.

## File Structure

```
lib/
├── services/
│   └── location_service.dart          # Location handling
├── models/
│   └── fps_shop.dart                  # FPS Shop model
├── providers/
│   └── fps_provider.dart              # FPS Provider with location logic
└── screens/
    └── citizen/
        └── fps_locator.dart           # Main FPS Locator screen
```

## Key Features

### Map Display
- Shows user's current location (blue marker)
- Shows FPS shops as red markers
- Auto-centers map on all nearby shops
- Supports zoom, pan, and compass controls

### Location Services
- Requests location permissions from user
- Gets current GPS location with high accuracy
- Calculates distance to each FPS shop
- Filters shops within 30km radius

### Search & Filter
- Real-time search by FPS name or area
- Distance sorting (nearest first)
- Interactive bottom sheet with FPS list

### Shop Details
- Name and owner information
- Address and location
- Operating hours
- Shop type (Regular/Specialized)
- Distance from user
- Call and directions buttons

### Language Support
- English, हिंदी, मराठी translations
- Localized UI text for maps and directions

## Testing the Feature

### 1. Test Location Permission Flow
```bash
flutter run
```
- Open FPS Locator tab
- When prompted, grant location access
- User's location appears on map

### 2. Test Location Detection
- Open FPS Locator
- Current location shown by blue marker
- All nearby shops displayed within 30km

### 3. Test Search
- Enter "Delhi" in search box
- List filters to show matching shops
- Map updates with filtered locations

### 4. Test Shop Details
- Tap any shop marker or list item
- Bottom sheet shows complete details
- Distance calculated and shown
- Call and directions buttons available

### 5. Test Language Switching
- Go to Settings
- Change language to हिंदी or मराठी
- Return to FPS Locator
- All text updates to selected language

## Dummy FPS Data

The app includes 6 sample FPS shops in the Delhi/NCR region:
1. New Delhi FPS (28.5355, 77.3910)
2. South Delhi FPS (28.5244, 77.2068)
3. East Delhi FPS (28.6069, 77.2705)
4. West Delhi FPS (28.5866, 77.0426)
5. Greater Noida FPS (28.4744, 77.5714)
6. Gurgaon FPS (28.4595, 77.0758)

### Adding More Shops
Edit `lib/providers/fps_provider.dart` and add to `_loadDummyFPSData()`:
```dart
FPSShop(
  id: 'fps_007',
  name: 'Your FPS Name',
  ownerName: 'Owner Name',
  address: 'Complete Address',
  latitude: 28.YYYY,
  longitude: 77.XXXX,
  phone: '+91-XXXXXXXXXX',
  openingTime: '08:00 AM',
  closingTime: '06:00 PM',
  type: 'Regular',
  isActive: true,
),
```

## API Key Setup for Production

1. Create separate API keys for debug and release builds
2. Use Android key restrictions for your app package name
3. Use iOS key restrictions for your app bundle identifier
4. Enable only necessary APIs (Maps, Geocoding)
5. Set up billing alerts in Google Cloud Console

## Troubleshooting

### Maps not loading
- Verify API key is correctly set
- Check API is enabled in Google Cloud Console
- Ensure app package name matches restrictions

### Location not getting
- Grant permission in Settings > Apps > Permissions
- Enable location services on device
- Check GPS signal (indoor limitations)

### Search not working
- Check FPS data in provider
- Verify search query matches shop names

### Directions/Call not working
- Install url_launcher package for production
- Link phone dialer and maps app to launcher

## Future Enhancements

1. Integrate with real backend API for FPS data
2. Add real GPS tracking/navigation
3. Implement favorites/saved locations
4. Add reviews and ratings
5. Real-time distribution schedule
6. Push notifications for nearby distributions

## Dependencies Added

```yaml
google_maps_flutter: ^2.8.0    # Google Maps display
geolocator: ^11.0.0            # Location services
geocoding: ^2.1.0              # Address conversion
```

## Support

For issues with Google Maps:
- [Google Maps Flutter Plugin Docs](https://pub.dev/packages/google_maps_flutter)
- [Geolocator Plugin Docs](https://pub.dev/packages/geolocator)
- [Geocoding Plugin Docs](https://pub.dev/packages/geocoding)
