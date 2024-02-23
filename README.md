# RetroAccess-App #

This repo contains source code for the RASSAR app.

## Introduction ##
RASSAR is an iOS app that scans indoor spaces and detect accessibility and safety issues in real time. The app is built upon ARKit and RoomPlan API, and relies on a YOLOV5 model to detect smaller indoor items that's related to accessibility and safety.
[[Website](https://makeabilitylab.cs.washington.edu/project/rassar/)] 
## How to use RASSAR##
To build RASSAR, simply clone this repo and open it with XCode ( >= 14.0). Then update the signing and build the app with destination selected as your iPhone.
The app can run on iphones with iOS version >=16.0. Please notify that the RASSAR app requires LiDAR scanners on phone thus only iPhone Pro/ProMax lineup from 12 on can successfully run this app.

## YOLOV5 model and dataset ##
To detect smaller indoor items related to accessibility and safety, we trained an object detection model based on the architecture of YOLOV4. The model weights, in the format of Apple's coreml model, can be found in RASSAR App/YOLOv5/yolov5-Medium.mlmodel

The dataset used for training this model can be downloaded from here: [[Dataset](https://drive.google.com/file/d/1JCkIIQWrFTTWDGzP_-3FhKjh091DB8TV/view?usp=sharing)].

## Related Work ##
