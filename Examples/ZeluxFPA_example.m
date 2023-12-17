% Make sure the "dirCam" property in the ZeluxFPA.m classdef is configured
% to the location of the Thorlabs.TSI.TLCamera.dll The default location is:
%       C:\Program Files\Thorlabs\Scientific Imaging\Scientific Camera Support\Scientific Camera Interfaces\SDK\DotNet Toolkit\dlls\Managed_64_lib\
% This code connects Three ThorLabs Zelux cameras, loads the ThorLabs SDK,
% configures their respective exposure times, captures images, disconnects
% the cameras, and then unloads the SDK.
clear *
clc

% -------------------------- Connect to cameras --------------------------
% Option 1:     Using the Serial Number of each camera
    cam1 = ZeluxFPA(12345);
    cam2 = ZeluxFPA(04321);
    cam3 = ZeluxFPA(17010);
% Option 2:     Using the index of the camera in the "stored_SNs" property
%   NOTE: This is only an option if you have updated the "stored_SNs"
%   property in the ZeluxFPA.m classdef, which would look something like
%   this: stored_SNs = [12345, 04321, 17010];
%     cam1 = ZeluxFPA(1);
%     cam2 = ZeluxFPA(2);
%     cam3 = ZeluxFPA(3);
    

cam1.init(); % When you initialize the first camera, the SDK will be loaded.
cam2.tlCameraSDK = cam1.tlCameraSDK; % Copy the SDK to the other cameras
cam3.tlCameraSDK = cam1.tlCameraSDK;

cam2.init(); % After ensuring the SDK is copied, the other cameras can be initialized
cam3.init();

cam1.open(); % Now we open the cameras so we can start using them
cam2.open();
cam3.open();
% ------------------------------------------------------------------------

cam1.setExpT(0.04); % Set the exposure time (in milliseconds)
cam2.setExpT(1.2);
cam3.setExpT(0.8);

im1 = cam1.capAverage(10);	% Capture 10 frames and average them. Returns the average.
im2 = cam2.capture(1);      % Capture a single image.
im3 = cam3.capture(10);     % Capture 10 consecutive frames. Returns a cell with all the images.

% -------------------------- Close the cameras ---------------------------
cam1.close();
cam2.close();
cam3.close();

cam1.closeSDK(); % The SDK only needs to be closed in the first camera,
                 % because that's where it was initially loaded.
% Note: It is extremely important to close the cameras and SDK in the
% correct order, otherwise they get stuck in a communication loop and you
% may need to restart the computer.
% ------------------------------------------------------------------------

