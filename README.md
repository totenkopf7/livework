# LiveWork View

A real-time task and hazard tracking system for construction sites with custom map integration.

## Features

- **Work & Hazard Reports**: Create detailed reports with photos and location data
- **Custom Company Map**: Upload your company's map and tap to select work locations
- **Real-time Dashboard**: View all reports with filtering and status updates
- **Map View**: Visual representation of work locations on your custom map
- **Task Completion**: Mark tasks as completed and move them to the Reports tab
- **Location Tracking**: GPS coordinates and custom map coordinates
- **Image Support**: Capture and display photos with reports

## Custom Map Setup

1. **Add Your Company Map**:
   - Place your company's map image in `assets/images/`
   - Name it `company_map.png` (or update the path in code)
   - Recommended: PNG format, 800x600 or higher resolution

2. **Map Features**:
   - Tap anywhere on the map to select work locations
   - Visual markers show work and hazard locations
   - Coordinates stored as percentages for accuracy
   - Works on both web and mobile platforms

## Getting Started

1. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Add Your Map**:
   - Copy your company map to `assets/images/company_map.png`

3. **Run the App**:
   ```bash
   flutter run -d web-server --web-port 8080
   ```

## Usage

1. **Create Reports**:
   - Select report type (Work/Hazard)
   - Choose zone
   - Add description
   - Take photos
   - Tap on map to select location
   - Submit report

2. **View Dashboard**:
   - See all active reports
   - Filter by type and status
   - Toggle between list and map view

3. **Complete Tasks**:
   - Press "Task completed" button
   - Report moves to "Reports" tab
   - View completed work history

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── dashboard_page.dart       # Main dashboard
├── report_creation_page.dart # Report creation form
├── data/models/             # Data models
├── providers/               # State management
├── widgets/                 # Reusable components
│   ├── custom_map_widget.dart    # Custom map implementation
│   ├── report_card_widget.dart   # Report display cards
│   └── filter_panel_widget.dart  # Filter controls
└── pages/                  # Additional pages
```

## Dependencies

- **provider**: State management
- **image_picker**: Photo capture
- **geolocator**: GPS location
- **firebase_core**: Backend integration (future)
- **cloud_firestore**: Database (future)

## Customization

- **Map Image**: Replace `assets/images/company_map.png`
- **Zones**: Update zone data in `SiteProvider`
- **Colors**: Modify theme in `main.dart`
- **Fields**: Extend `ReportModel` for additional data

## Future Enhancements

- Firebase integration for real-time sync
- Offline support
- User authentication
- Advanced filtering
- Export reports
- Push notifications 