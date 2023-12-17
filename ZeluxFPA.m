classdef ZeluxFPA < handle
    % This is a class to control the ThorLabs ELL18 rotation stage
    
    properties
        stored_SNs = [09944, 09945, 14030, 14238, 14239, 14029, 14057, 14058];
        dirCam = 'C:\Program Files\Thorlabs\Scientific Imaging\Scientific Camera Support\Scientific Camera Interfaces\SDK\DotNet Toolkit\dlls\Managed_64_lib\';
        
        exp_t = 0.04; % [ms] exposure time. min = 0.04  max = 20,000


        SN;
        tlCameraSDK = 0;
        serialNumbers;
        tlCamera;

    end
    
    methods (Static)
        function obj = ZeluxFPA(camSN) % This is the constructor

            if nargin ~= 1 % Check to ensure
                error('Require a serial number or FPA number to initialize the FPA');
            end

            if camSN <= length(obj.stored_SNs) % If the camera's SN is stored above, it can be selected directly
                obj.SN = obj.stored_SNs(camSN);
            else 
                if (camSN < 1000) | (camSN > 20000) % If the user input is outside a certain range, return an error
                    error('Invalid camera number.');
                end
                obj.SN = camSN; % If the user input is within a range, assume it's the camera's SN
            end
            
        end
        
    end
    
    methods
%         function serialNumbers = getSNs(obj)
%             % Get serial numbers of connected TLCameras.
%             serialNumbers = obj.tlCameraSDK.DiscoverAvailableCameras;
% %             disp([num2str(serialNumbers.Count), ' camera was discovered.']);
%         end

        function init(obj)
            dirbackup = cd;
            cd(obj.dirCam);
            
            if obj.tlCameraSDK == 0
                obj.tlCameraSDK = TlFpaSdk_init(obj.dirCam);
            end
            obj.serialNumbers = obj.tlCameraSDK.DiscoverAvailableCameras;

            if obj.serialNumbers.Count == 0
                delete(obj.serialNumbers);
                obj.tlCameraSDK.Dispose;
                delete(obj.tlCameraSDK);
                % Exit with error
                cd(dirbackup);
                error('No ThorLabs Zelux cameras were found');
            end
            

            itemNum = -1;
            
            % Look for the Camera with the desired Serial Number
            for i=0 : obj.serialNumbers.Count-1
                if str2double(char(obj.serialNumbers.Item(i))) == obj.SN
                   itemNum = i; % If found, assign the Item # to itemNum
                end
            end
            
            % If the desired Serial number wasn't found
            if itemNum == -1 
                % Release the serial numbers
                delete(obj.serialNumbers);
    
                % Release the TLCameraSDK.
                obj.tlCameraSDK.Dispose;
                delete(obj.tlCameraSDK);
                
                % Exit with error
                cd(dirbackup);
                error('Camera with Serial Number: %d not found.',obj.SN);
            end
            cd(dirbackup);
        end

        function open(obj)
            disp('------------------------------------------');
            disp('---------------Opening FPA----------------');

            dirbackup = cd;
            cd(obj.dirCam);

            itemNum = -1;
            
            % Look for the Camera with the desired Serial Number
            for i=0 : obj.serialNumbers.Count-1
                if str2double(char(obj.serialNumbers.Item(i))) == obj.SN
                   itemNum = i; % If found, assign the Item # to itemNum
                end
            end
            
            % If the desired Serial number wasn't found
            if itemNum == -1 
                % Release the serial numbers
                delete(obj.serialNumbers);
    
                % Release the TLCameraSDK.
                obj.tlCameraSDK.Dispose;
                delete(obj.tlCameraSDK);
                
                % Exit with error
                error('Camera with Serial Number: %d not found.',camSN);
            end

            % Open the desired TLCamera using the serial number.
            obj.tlCamera = obj.tlCameraSDK.OpenCamera(obj.serialNumbers.Item(itemNum), false);
        
            % Set exposure time of the camera.
            obj.tlCamera.ExposureTime_us = obj.exp_t .*1000;
        
            % Set the FIFO frame buffer size. Default size is 1.
            obj.tlCamera.MaximumNumberOfFramesToQueue = 5;
        
           % Configure the camera for software triggering
            obj.tlCamera.OperationMode = Thorlabs.TSI.TLCameraInterfaces.OperationMode.SoftwareTriggered;

            cd(dirbackup);
            disp('----------------FPA Opened-----------------');
        end

        function closeSDK(obj)
            dirbackup = cd;
            cd(obj.dirCam);
            % Release the TLCameraSDK.
            obj.tlCameraSDK.Dispose;
            delete(obj.tlCameraSDK);
            cd(dirbackup);
        end

        function close(obj)
            disp('---------------Closing FPA----------------');
            dirbackup = cd;
            cd(obj.dirCam);

            % Release the TLCamera
            obj.tlCamera.Dispose;
            delete(obj.tlCamera);
        
        
            % Release the serial numbers
            delete(obj.serialNumbers);

            cd(dirbackup);
            disp('---------------FPA Closed----------------');
            disp('-----------------------------------------');
            
        end
        
        function setExpT(obj, t)
            dirbackup = cd;
            cd(obj.dirCam);

            obj.exp_t = t;
            % Set exposure time of the camera.
            obj.tlCamera.ExposureTime_us = obj.exp_t .*1000;

            cd(dirbackup);
        end

        function im = capture(obj, n)
            dirbackup = cd;
            cd(obj.dirCam);

            obj.tlCamera.FramesPerTrigger_zeroForUnlimited = n;
            obj.tlCamera.Arm;
            obj.tlCamera.IssueSoftwareTrigger; % trigger the capture

            im = cell(n); % preallocate memory for speed

            frameCount = 0;
            while frameCount < n
                % Check if image buffer has been filled
                if (obj.tlCamera.NumberOfQueuedFrames > 0)
        
                    % If data processing in Matlab falls behind camera image
                    % acquisition, the FIFO image frame buffer could overflow,
                    % which would result in missed frames.
                    if (obj.tlCamera.NumberOfQueuedFrames > 1)
                        disp(['Data processing falling behind acquisition. ' num2str(obj.tlCamera.NumberOfQueuedFrames) ' remains']);
                    end
        
                    % Get the pending image frame.
                    imageFrame = obj.tlCamera.GetPendingFrameOrNull;
                    if ~isempty(imageFrame)
                        frameCount = frameCount + 1;
        
                        % Get the image data as 1D uint16 array
                        imageData = uint16(imageFrame.ImageData.ImageData_monoOrBGR);
        
                        % Reshape 1D array to 2D image
                        imageHeight = imageFrame.ImageData.Height_pixels;
                        imageWidth = imageFrame.ImageData.Width_pixels;
                        im{frameCount} = reshape(imageData, [imageWidth, imageHeight])';
        
                    end
        
                    % Release the image frame
                    delete(imageFrame);
                end
            end
            obj.tlCamera.Disarm;
            cd(dirbackup);
        end

        function image = capAverage(obj, n)
            im = obj.capture(n);
            if n > 1
                image = zeros(size(im{1}(:,:,1)));
                for i=1 : n
                   image = image + double(im{i}(:,:,1));
                end
                image = image./n;
            else
                image = im{1}; 
            end
        end
        
    end % Methods end

end% Classdef end


function tlCameraSDK = TlFpaSdk_init(SDK_dir)
    dirBackup = cd;
    cd(SDK_dir);

    NET.addAssembly([pwd, '\Thorlabs.TSI.TLCamera.dll']);
    disp('Dot NET assembly loaded.');

    tlCameraSDK = Thorlabs.TSI.TLCamera.TLCameraSDK.OpenTLCameraSDK;

    cd(dirBackup);

end
