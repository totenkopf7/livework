# LiveWork View - Deployment Guide

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Firebase Project Setup](#firebase-project-setup)
4. [Mobile Application Deployment](#mobile-application-deployment)
5. [Web Dashboard Deployment](#web-dashboard-deployment)
6. [Environment Configuration](#environment-configuration)
7. [Security Configuration](#security-configuration)
8. [Monitoring and Logging](#monitoring-and-logging)
9. [Backup and Recovery](#backup-and-recovery)
10. [Post-Deployment Verification](#post-deployment-verification)

## Overview

This deployment guide provides step-by-step instructions for deploying the LiveWork View application to production environments. The guide covers both mobile application deployment to app stores and web dashboard deployment to Firebase Hosting.

### Deployment Architecture

The LiveWork View application consists of three main components:
- **Mobile Application:** Flutter-based Android and iOS applications
- **Web Dashboard:** Flutter Web application hosted on Firebase Hosting
- **Backend Services:** Firebase Firestore, Storage, Authentication, and Functions

### Deployment Environments

- **Development:** Local development environment with Firebase emulators
- **Staging:** Pre-production environment for testing and validation
- **Production:** Live environment for end users

## Prerequisites

### Required Tools and Accounts

1. **Development Tools:**
   - Flutter SDK 3.16.0 or later
   - Android Studio with Android SDK
   - Xcode (for iOS deployment, macOS required)
   - Firebase CLI
   - Git version control

2. **Accounts and Credentials:**
   - Google Cloud Platform account with billing enabled
   - Apple Developer Program membership (for iOS deployment)
   - Google Play Console developer account (for Android deployment)
   - Domain name and DNS management access (for custom domain)

3. **Certificates and Keys:**
   - Android signing key and keystore
   - iOS distribution certificates and provisioning profiles
   - Firebase service account keys
   - SSL certificates for custom domains

### System Requirements

**Development Machine:**
- Operating System: macOS, Windows, or Linux
- RAM: 8GB minimum, 16GB recommended
- Storage: 50GB available space
- Internet: Stable broadband connection

**Target Devices:**
- Android: API level 24 (Android 7.0) or higher
- iOS: iOS 12.0 or higher
- Web: Modern browsers (Chrome 88+, Firefox 85+, Safari 14+, Edge 88+)

## Firebase Project Setup

### Creating Firebase Project

1. **Access Firebase Console:**
   ```bash
   # Open Firebase Console in browser
   https://console.firebase.google.com
   ```

2. **Create New Project:**
   - Click "Create a project"
   - Enter project name: "livework-view-prod"
   - Enable Google Analytics (recommended)
   - Select or create Analytics account
   - Accept terms and create project

3. **Configure Project Settings:**
   - Navigate to Project Settings (gear icon)
   - Note the Project ID for later use
   - Configure project description and public settings

### Enabling Firebase Services

1. **Firestore Database:**
   ```bash
   # Navigate to Firestore Database in console
   # Click "Create database"
   # Select "Start in production mode"
   # Choose database location (select closest to users)
   ```

2. **Firebase Storage:**
   ```bash
   # Navigate to Storage in console
   # Click "Get started"
   # Review security rules
   # Select storage location
   ```

3. **Authentication:**
   ```bash
   # Navigate to Authentication in console
   # Click "Get started"
   # Select "Sign-in method" tab
   # Enable "Email/Password" provider
   # Configure authorized domains
   ```

4. **Firebase Hosting:**
   ```bash
   # Navigate to Hosting in console
   # Click "Get started"
   # Note the default domain provided
   # Configure custom domain if required
   ```

### Firebase CLI Setup

1. **Install Firebase CLI:**
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase:**
   ```bash
   firebase login
   ```

3. **Initialize Project:**
   ```bash
   # Navigate to project root directory
   firebase init
   
   # Select services:
   # - Firestore
   # - Storage
   # - Hosting
   # - Functions (if using)
   
   # Select existing project: livework-view-prod
   # Configure Firestore rules and indexes
   # Configure Storage rules
   # Set public directory for hosting
   ```

## Mobile Application Deployment

### Android Deployment

1. **Prepare Android Build:**
   ```bash
   # Navigate to mobile app directory
   cd livework_view_mobile
   
   # Clean previous builds
   flutter clean
   flutter pub get
   
   # Build release APK
   flutter build apk --release
   
   # Build App Bundle (recommended for Play Store)
   flutter build appbundle --release
   ```

2. **Sign Android App:**
   ```bash
   # Create keystore (first time only)
   keytool -genkey -v -keystore ~/livework-release-key.keystore \
     -alias livework -keyalg RSA -keysize 2048 -validity 10000
   
   # Configure signing in android/app/build.gradle
   # Add keystore configuration to android/key.properties
   ```

3. **Google Play Console Setup:**
   - Access Google Play Console
   - Create new application
   - Complete app information and content rating
   - Upload signed App Bundle
   - Configure store listing and screenshots
   - Submit for review

### iOS Deployment

1. **Prepare iOS Build:**
   ```bash
   # Ensure iOS development environment is set up
   # Open iOS project in Xcode
   open ios/Runner.xcworkspace
   
   # Configure signing and capabilities
   # Set deployment target to iOS 12.0
   # Configure app icons and launch screens
   ```

2. **Build iOS Archive:**
   ```bash
   # Build iOS release
   flutter build ios --release
   
   # Archive in Xcode
   # Product > Archive
   # Distribute App > App Store Connect
   ```

3. **App Store Connect Setup:**
   - Access App Store Connect
   - Create new app record
   - Complete app information and metadata
   - Upload build using Xcode or Transporter
   - Configure App Store listing
   - Submit for App Store review

### Mobile App Configuration

1. **Firebase Configuration:**
   ```bash
   # Download google-services.json for Android
   # Place in android/app/ directory
   
   # Download GoogleService-Info.plist for iOS
   # Add to iOS project in Xcode
   ```

2. **Environment Configuration:**
   ```dart
   // lib/core/config/environment.dart
   class Environment {
     static const String firebaseProjectId = 'livework-view-prod';
     static const String apiUrl = 'https://api.liveworkview.com';
     static const bool isProduction = true;
   }
   ```

## Web Dashboard Deployment

### Build Web Application

1. **Prepare Web Build:**
   ```bash
   # Navigate to web app directory
   cd livework_view_web
   
   # Clean and get dependencies
   flutter clean
   flutter pub get
   
   # Build for web
   flutter build web --release
   ```

2. **Optimize Build:**
   ```bash
   # Enable web optimizations
   flutter build web --release --web-renderer html
   
   # Verify build output
   ls -la build/web/
   ```

### Firebase Hosting Deployment

1. **Configure Hosting:**
   ```json
   // firebase.json
   {
     "hosting": {
       "public": "build/web",
       "ignore": [
         "firebase.json",
         "**/.*",
         "**/node_modules/**"
       ],
       "rewrites": [
         {
           "source": "**",
           "destination": "/index.html"
         }
       ],
       "headers": [
         {
           "source": "**/*.@(js|css)",
           "headers": [
             {
               "key": "Cache-Control",
               "value": "max-age=31536000"
             }
           ]
         }
       ]
     }
   }
   ```

2. **Deploy to Firebase Hosting:**
   ```bash
   # Deploy to Firebase Hosting
   firebase deploy --only hosting
   
   # Verify deployment
   firebase hosting:channel:list
   ```

### Custom Domain Configuration

1. **Add Custom Domain:**
   ```bash
   # Add domain in Firebase Console
   # Navigate to Hosting > Add custom domain
   # Enter domain name: dashboard.liveworkview.com
   # Follow DNS configuration instructions
   ```

2. **DNS Configuration:**
   ```bash
   # Add DNS records as instructed by Firebase
   # Type: A
   # Name: dashboard
   # Value: [Firebase IP addresses]
   
   # Verify DNS propagation
   nslookup dashboard.liveworkview.com
   ```

## Environment Configuration

### Production Environment Variables

1. **Firebase Configuration:**
   ```javascript
   // web/firebase-config.js
   const firebaseConfig = {
     apiKey: "your-api-key",
     authDomain: "livework-view-prod.firebaseapp.com",
     projectId: "livework-view-prod",
     storageBucket: "livework-view-prod.appspot.com",
     messagingSenderId: "123456789012",
     appId: "1:123456789012:web:abcdef123456"
   };
   ```

2. **Application Configuration:**
   ```dart
   // lib/core/config/app_config.dart
   class AppConfig {
     static const String environment = 'production';
     static const String apiBaseUrl = 'https://api.liveworkview.com';
     static const bool enableLogging = false;
     static const bool enableAnalytics = true;
   }
   ```

### Database Configuration

1. **Firestore Indexes:**
   ```bash
   # Deploy Firestore indexes
   firebase deploy --only firestore:indexes
   
   # Verify indexes in Firebase Console
   ```

2. **Security Rules:**
   ```bash
   # Deploy Firestore security rules
   firebase deploy --only firestore:rules
   
   # Test rules in Firebase Console Rules Playground
   ```

## Security Configuration

### Firestore Security Rules

1. **Production Security Rules:**
   ```javascript
   // firestore.rules
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Sites collection
       match /sites/{siteId} {
         allow read: if isAuthenticated() && hasAccessToSite(siteId);
         allow write: if isAuthenticated() && isAdmin();
       }
       
       // Reports collection
       match /reports/{reportId} {
         allow read: if isAuthenticated() && hasAccessToReportSite(reportId);
         allow create: if isAuthenticated() && isValidReportData();
         allow update: if isAuthenticated() && canModifyReport(reportId);
         allow delete: if isAuthenticated() && isAdmin();
       }
       
       // Users collection
       match /users/{userId} {
         allow read: if isAuthenticated() && 
           (request.auth.uid == userId || isAdmin());
         allow write: if isAuthenticated() && 
           (request.auth.uid == userId || isAdmin());
       }
     }
   }
   ```

2. **Storage Security Rules:**
   ```javascript
   // storage.rules
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       match /sites/{siteId}/{allPaths=**} {
         allow read: if isAuthenticated() && hasAccessToSite(siteId);
         allow write: if isAuthenticated() && isAdminOrSupervisor();
       }
       
       match /reports/{reportId}/{allPaths=**} {
         allow read: if isAuthenticated() && hasAccessToReport(reportId);
         allow write: if isAuthenticated() && isReportOwner(reportId);
       }
     }
   }
   ```

### Authentication Configuration

1. **Configure Auth Providers:**
   ```bash
   # Enable email/password authentication
   # Configure password requirements
   # Set up email verification
   # Configure password reset emails
   ```

2. **Custom Claims Setup:**
   ```javascript
   // functions/src/auth.js
   exports.setCustomClaims = functions.auth.user().onCreate(async (user) => {
     const customClaims = {
       role: 'reporter',
       sites: [],
       permissions: ['reports.read', 'reports.write']
     };
     
     await admin.auth().setCustomUserClaims(user.uid, customClaims);
   });
   ```

## Monitoring and Logging

### Firebase Performance Monitoring

1. **Enable Performance Monitoring:**
   ```dart
   // Add to mobile app
   import 'package:firebase_performance/firebase_performance.dart';
   
   // Initialize in main.dart
   await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
   ```

2. **Custom Performance Traces:**
   ```dart
   // Track custom operations
   final trace = FirebasePerformance.instance.newTrace('report_submission');
   await trace.start();
   // Perform operation
   await trace.stop();
   ```

### Error Tracking and Logging

1. **Crashlytics Setup:**
   ```dart
   // Add Firebase Crashlytics
   import 'package:firebase_crashlytics/firebase_crashlytics.dart';
   
   // Initialize error handling
   FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
   ```

2. **Custom Logging:**
   ```dart
   // Custom event logging
   FirebaseAnalytics.instance.logEvent(
     name: 'report_created',
     parameters: {
       'site_id': siteId,
       'report_type': reportType,
     },
   );
   ```

### Monitoring Dashboard Setup

1. **Firebase Console Monitoring:**
   - Set up alerts for error rates
   - Monitor performance metrics
   - Track user engagement
   - Monitor quota usage

2. **Custom Monitoring:**
   ```bash
   # Set up external monitoring
   # Configure uptime monitoring
   # Set up performance alerts
   # Monitor API response times
   ```

## Backup and Recovery

### Automated Backup Configuration

1. **Firestore Backup:**
   ```bash
   # Set up automated Firestore exports
   gcloud firestore export gs://livework-view-backups/$(date +%Y%m%d)
   
   # Schedule daily backups
   # Configure retention policies
   ```

2. **Storage Backup:**
   ```bash
   # Set up Storage bucket backup
   gsutil -m cp -r gs://livework-view-prod.appspot.com gs://livework-view-backups/storage/$(date +%Y%m%d)
   ```

### Disaster Recovery Planning

1. **Recovery Procedures:**
   - Document recovery time objectives (RTO)
   - Define recovery point objectives (RPO)
   - Create step-by-step recovery procedures
   - Test recovery procedures regularly

2. **Backup Verification:**
   ```bash
   # Verify backup integrity
   # Test data restoration
   # Validate backup completeness
   # Document verification results
   ```

## Post-Deployment Verification

### Functional Testing

1. **Mobile App Testing:**
   ```bash
   # Test core functionality
   # - User authentication
   # - Report creation and submission
   # - Photo upload and storage
   # - Offline synchronization
   # - Push notifications
   ```

2. **Web Dashboard Testing:**
   ```bash
   # Test dashboard functionality
   # - Real-time data updates
   # - Map visualization
   # - Report management
   # - User administration
   # - Data export
   ```

### Performance Verification

1. **Load Testing:**
   ```bash
   # Test concurrent user load
   # Verify response times
   # Monitor resource usage
   # Test auto-scaling behavior
   ```

2. **Security Testing:**
   ```bash
   # Verify authentication flows
   # Test authorization controls
   # Validate data encryption
   # Check for security vulnerabilities
   ```

### User Acceptance Testing

1. **Stakeholder Testing:**
   - Conduct user acceptance testing with key stakeholders
   - Validate business requirements
   - Collect feedback and address issues
   - Document test results

2. **Training and Documentation:**
   - Provide user training sessions
   - Distribute user manuals and guides
   - Set up support channels
   - Create troubleshooting documentation

### Go-Live Checklist

- [ ] All environments deployed and tested
- [ ] Security configurations verified
- [ ] Monitoring and alerting configured
- [ ] Backup and recovery procedures tested
- [ ] User accounts created and configured
- [ ] Training completed for all user groups
- [ ] Support procedures documented and communicated
- [ ] Performance benchmarks met
- [ ] Security audit completed
- [ ] Compliance requirements verified

---

**Document Information:**
- **Version:** 1.0
- **Last Updated:** January 2024
- **Next Review:** March 2024
- **Document Owner:** DevOps Team

