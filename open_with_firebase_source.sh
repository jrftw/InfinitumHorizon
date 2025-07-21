#!/bin/bash

# Script to open Infinitum Horizon project with Firebase Firestore source distribution
# This is required for visionOS support

echo "Opening Infinitum Horizon with Firebase Firestore source distribution..."
echo "This enables visionOS support for Firebase Firestore"

export FIREBASE_SOURCE_FIRESTORE=1
open "Infinitum Horizon.xcodeproj"

echo "Project opened successfully!"
echo "Note: Keep this terminal open while working on the project to maintain the environment variable" 