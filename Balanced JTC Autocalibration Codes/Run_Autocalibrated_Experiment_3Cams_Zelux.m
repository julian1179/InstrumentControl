clear *
clc


%---------------------Experiment filenames and directory-------------------
cd('C:\Users\LAPT\Desktop\Synchronized Experiments\HOC Research\Captures_3Cam\Auto-calibrated Experiment codes, 2024');
base_dir =      'C:\Users\LAPT\Desktop\Synchronized Experiments\Large experimental data\HOC Research\Captures_3Cam\Auto-calibrated Experiments\'; %Base directory for the experiments
calib_im_dir =  'C:\Users\LAPT\Desktop\Synchronized Experiments\Large experimental data\HOC Research\Captures_3Cam\Calibration\';
exp_im_dir = [base_dir,'Original Images\Aarushi\Exp102\'];

exp_num = '102'; %

autoExposure = 1; % Set to 1 to turn on autoexposure.
autoExposure_calib_corr = 2; % Which correlation in the CSV will be used to calibrate the exposure time using autoExposure

% SLM Directory
SLM1_dir = 'Z:\DCIM\';
SLM2_dir = 'Y:\DCIM\';
pwr = 0.01; % W
caps = 10; % Number of captures to average.
% Cameras used for [Interference, Que, Ref]
cams = [4, 3, 5]; % [Int, SLM1, SLM2]
exp_t = [60, 30, 30]; % [ms]

SLM_load_time = 3;

[pSLM1angle, pSLM2angle, angleQue, angleRef, intCc, queCc, refCc] = CalibrateCameraRotation(SLM1_dir, SLM2_dir, caps, cams, exp_t, calib_im_dir, 0);

if (pSLM1angle > 7) || (pSLM2angle > 7)
    error('SLM angles are too large. Double check that the laser power isn''t saturating the cameras');
end

% FigQue = 'AFRC_Wide'; % Que  
% FigRef = 'AFRC_Wide'; % Ref


% Select the directory for the experiment.
exp_dir = [base_dir, 'Exp', exp_num, '\'];

% Read the experiment CSV
expList = readtable([exp_dir,'Exp',exp_num,'_inputList.csv'],"Delimiter","comma");


%% Initialize the cameras

disp('-------------------------Connecting to FPAs-------------------------');
camInt = ZeluxFPA(cams(1));             camQue = ZeluxFPA(cams(2));              camRef = ZeluxFPA(cams(3));

camInt.init();                           camQue.tlCameraSDK = camInt.tlCameraSDK;  camRef.tlCameraSDK = camInt.tlCameraSDK;

                                         camQue.init();                            camRef.init();

camInt.open();                           camQue.open();                            camRef.open();

camInt.setExpT(exp_t(1));                camQue.setExpT(exp_t(2));                 camRef.setExpT(exp_t(3));

% clc
disp('---------------------------FPAs Connected---------------------------');

%%
[SLM1_Scaling, SLM2_Scaling, camQue_factor, camRef_factor] = calibBrightness(camInt, camQue, camRef, caps, SLM1_dir, SLM2_dir, calib_im_dir, 'calib_grid.bmp', 'Black_screen.jpg');
camQue_factor = 1;
camRef_factor = 1;
if autoExposure == 1
    % Calibrate the exposure time
    FigRef = expList.Ref{autoExposure_calib_corr}; % SLM2
    FigQue = expList.Que{autoExposure_calib_corr}; % SLM1

    imQueName = sprintf('Exp%s_autoExpose_Que_%s.bmp', exp_num,FigQue(1:end-4));
    im1 = im2gray(imread([exp_im_dir,FigQue]));
    im1 = SLM1_Scaling.*imrotate(im1,pSLM1angle, 'bilinear');
    [sz1,sz2] = size(im1);
    imQue = uint8(zeros(480, 854));
    imQue(240-floor(sz1/2) : 240+round(sz1/2)-1  ,  427-floor(sz2/2) : 427+round(sz2/2)-1) = uint8(im1);
    
    imRefName = sprintf('Exp%s_autoExpose_Ref_%s.bmp', exp_num,FigRef(1:end-4));
    im2 = fliplr(im2gray(imread([exp_im_dir,FigRef])));
    im2 = SLM2_Scaling.*imrotate(im2,pSLM2angle, 'bilinear');
    [sz1,sz2] = size(im2);
    imRef = uint8(zeros(480, 854));
    imRef(240-floor(sz1/2) : 240+round(sz1/2)-1  ,  427-floor(sz2/2) : 427+round(sz2/2)-1) = uint8(im2);
    
    imwrite(imQue,[exp_dir,imQueName]);
    imwrite(imRef,[exp_dir,imRefName]);
    SLMImLoad(SLM1_dir, exp_dir, imQueName, SLM_load_time);
    SLMImLoad(SLM2_dir, exp_dir, imRefName, SLM_load_time);
    exp_t_int = AutoExposure(camInt, 10);
    % exp_t_que = AutoExposure(camQue, 10);
    % exp_t_ref = AutoExposure(camRef, 10);
    exp_t = [exp_t_int, round(exp_t_int/2,2), round(exp_t_int/2,2)];
    
end

% Set the exposure time again, since the calibBrightness() function
% modifies it
camInt.setExpT(exp_t(1));                camQue.setExpT(exp_t(2));                 camRef.setExpT(exp_t(3));

%%
tic;
for i = 1 : height(expList)
    corrNum = num2str(i);
    FigRef = expList.Ref{i}; % SLM2
    FigQue = expList.Que{i}; % SLM1

    cap_dir = [exp_dir, 'Corr', corrNum, '\'];
    
    % Check to see that we're not overriding an older experiment and create the
    % new explanation text file with the relevant data.
    newExperiment(cap_dir, corrNum, FigRef, FigQue, pwr, caps, pSLM1angle,SLM1_Scaling, pSLM2angle,SLM2_Scaling, angleQue, angleRef, intCc, queCc, refCc)

    %% Condition the images according to the calibration

    imQueName = sprintf('Exp%s_Corr%d_Que_%s.bmp', exp_num,i,FigQue(1:end-4));
    im1 = im2gray(imread([exp_im_dir,FigQue]));
    im1 = SLM1_Scaling.*imrotate(im1,pSLM1angle, 'bilinear');
    [sz1,sz2] = size(im1);
    imQue = uint8(zeros(480, 854));
    imQue(240-floor(sz1/2) : 240+round(sz1/2)-1  ,  427-floor(sz2/2) : 427+round(sz2/2)-1) = uint8(im1);

    imRefName = sprintf('Exp%s_Corr%d_Ref_%s.bmp', exp_num,i,FigRef(1:end-4));
    im2 = fliplr(im2gray(imread([exp_im_dir,FigRef])));
    im2 = SLM2_Scaling.*imrotate(im2,pSLM2angle, 'bilinear');
    [sz1,sz2] = size(im2);
    imRef = uint8(zeros(480, 854));
    imRef(240-floor(sz1/2) : 240+round(sz1/2)-1  ,  427-floor(sz2/2) : 427+round(sz2/2)-1) = uint8(im2);
    

    %% Load the calibrated images into the SLMs
    imwrite(imQue,[cap_dir,imQueName]);
    imwrite(imRef,[cap_dir,imRefName]);
    SLMImLoad(SLM1_dir, cap_dir, imQueName, SLM_load_time);
    SLMImLoad(SLM2_dir, cap_dir, imRefName, SLM_load_time);
    
    %% --------------------------------------------------------------------------
    % Take measurements
    Int = camInt.capAverage(caps);
    Que = camQue.capAverage(caps);
    Ref = camRef.capAverage(caps);
    
    %% Extend images to 16 bits for max resolution on the averaged captures
    % We don't rescale, as the relative intesity between each image is
    % important.
    
    % Zelux cameras have an inherent bit depth of 10. Recall that A and B
    % are obtained through 'Measure_Average_Z' so it will contain decimal
    % values, hence extending the depth to 16 to preserve as much 
    % brightness resolution as possible.
    Intr = Int.*(2^16 -1)./(2^10 -1);
    Quer = Que.*(2^16 -1)./(2^10 -1) ;%.*2 ./ camQue_factor;
    Refr = Ref.*(2^16 -1)./(2^10 -1) ;%.*2 ./ camRef_factor;
    
    % Save images
    imwrite(uint16(Intr), [cap_dir, corrNum, '.Int.png'], 'bitdepth', 16);
    imwrite(uint16(Quer), [cap_dir, corrNum, '.Que-', FigQue(1:end-4), '.png'], 'bitdepth', 16);
    imwrite(uint16(Refr), [cap_dir, corrNum, '.Ref-', FigRef(1:end-4), '.png'], 'bitdepth', 16);
end
time = toc;
%%
disp('-------------------------Disconnecting to FPAs-------------------------');
camInt.close();  camQue.close();  camRef.close();

camInt.closeSDK();
disp('---------------------------FPAs Disconnected---------------------------');

%%
% Save workspace
% First check if file exists.
if ~isfile([exp_dir,'Exp', exp_num, ' workspace.mat'])
    % If file doesn't exist, then save workspace. This helps to prevent
    % accidental overwriting of the saved workspace.
    save([exp_dir,'Exp', exp_num, ' workspace']);
end

beep; pause(0.22); beep;
fprintf('Success! It took %.2f seconds to take all measurements.', time);
fprintf('\n\nThey are now stored at:\n%s\n\n', exp_dir);

%% ========================================================================
%  ========================== Functions and such ==========================
%  ========================================================================

function [SLM1_Scaling, SLM2_Scaling, cam1_factor, cam2_factor] = calibBrightness(camInt, cam1, cam2, caps, SLM1_dir, SLM2_dir, calib_im_dir, imCal, calib_black)
% This function turns on one SLM at a time and measures relative peak power
% of each SLM at the interference FPA. It then returns which SLM is
% yielding higher power, and what the power ratio is.
% The values of the strong SLM should then be scaled down by this ratio.
    
    % Set SLM2 to black and SLM1 to the calibration image
    SLMImLoad(SLM2_dir, calib_im_dir, calib_black, 3);
    SLMImLoad(SLM1_dir, calib_im_dir, imCal, 3);

    % Autoexpose to find the corresponding brightness at the FPA
    [exp_t_Int1, maxVal_Int1] = AutoExposure(camInt, caps);
    [exp_t_cam1, maxVal_cam1] = AutoExposure(cam1, caps);
    

    % Set SLM1 to black and SLM2 to the calibration image
    SLMImLoad(SLM1_dir, calib_im_dir, calib_black, 3);
    SLMImLoad(SLM2_dir, calib_im_dir, imCal, 3);
    
    % Autoexpose to find the corresponding brightness at the FPA
    [exp_t_Int2, maxVal_Int2] = AutoExposure(camInt, caps);
    [exp_t_cam2, maxVal_cam2] = AutoExposure(cam1, caps);

    pow_Int1 = maxVal_Int1/exp_t_Int1; % [power / sec]    
    pow_Int2 = maxVal_Int2/exp_t_Int2; % [power / sec]

    pow_cam1 = maxVal_cam1/exp_t_cam1; % [power / sec]
    pow_cam2 = maxVal_cam2/exp_t_cam2; % [power / sec]

    cam1_factor = pow_cam1 ./ pow_Int1;
    cam2_factor = pow_cam2 ./ pow_Int1;

    if pow_Int1 > pow_Int2
        SLM1_Scaling = pow_Int2/pow_Int1;
        SLM2_Scaling = 1;
    else
        SLM2_Scaling = 1;
        SLM1_Scaling = pow_Int1/pow_Int2;
    end
    
    
end

function [exp_t, maxVal] = AutoExposure(cam, caps)
    
    exp_t = 10; % [ms] Initial guess
    cam.setExpT(exp_t);
    im = cam.capAverage(caps);

    prev_exp_t = 0;
    exp_t_min = 0.04; % Physical minimum imposed by the Zelux camera
    exp_t_max = 40; % Arbitrary maximum
    maxVal = max(im(:));
    iter_count = 0;
    while (maxVal >= 1000 || maxVal <= 900) && (abs(prev_exp_t-exp_t)/exp_t >= 0.05) && (iter_count < 20)
        iter_count = iter_count +1;
        prev_exp_t = exp_t;

        if maxVal >= 1000 % Exposure too high
            exp_t_max = exp_t;
            exp_t = (exp_t-exp_t_min)/2 + exp_t_min;

        elseif maxVal <= 900 % Exposure too low
            exp_t_min = exp_t;
            exp_t = (exp_t_max-exp_t)/2 + exp_t;

        end
        exp_t = round(exp_t,2);
        
        cam.setExpT(exp_t);
        im = cam.capAverage(caps);
        maxVal = max(im(:));

    end
    
end


function SLMImLoad(SLM_dir, dirIm, nameIm, tImChange)
    % Prepare the SLM directory to receive the image
    contents = dir(SLM_dir); % Check the SLM directory for what images may exist
    contents = contents(~ismember({contents.name}, {'.', '..','desktop.ini'})); % Remove system files from our results
    exists = false;
    for k=1 : size(contents,1) % Scan the file names in the SLM directory
        % If any file name matches the image we want, note it down
       exists = exists || strcmp(contents(k).name,nameIm); 
    end
    
    if ~exists % If the image isn't already in the SLM
        copyfile([dirIm,nameIm],[SLM_dir,nameIm],'f')
    end
    
    pause(tImChange); % Allow time for the image to copy over
    
    % Delete all other images in the directory
    contents = dir(SLM_dir); % Update our list of files in the directory
    contents = contents(~ismember({contents.name}, {'.', '..','desktop.ini'})); % Remove system files from our results
    for k=1 : size(contents,1) % Scan the file names in the SLM's memory
        if ~strcmp(contents(k).name,nameIm)
            % Delete all files except the one we want
            delete([SLM_dir,contents(k).name]);
        end
    end
end


function SLMImSave(SLM_dir, nameIm, im, tImChange)
    % Prepare the SLM directory to receive the image
    contents = dir(SLM_dir); % Check the SLM directory for what images may exist
    contents = contents(~ismember({contents.name}, {'.', '..','desktop.ini'})); % Remove system files from our results
    exists = false;
    for k=1 : size(contents,1) % Scan the file names in the SLM directory
        % If any file name matches the image we want, note it down
       exists = exists || strcmp(contents(k).name,nameIm); 
    end
    
    if exists % If an image with the same name exists in the SLM directory
        nameIm = [nameIm(1:end-4),'(1)', nameIm(end-3:end)];
    end
    imwrite(uint8(im), [SLM_dir,nameIm]);
    
    pause(tImChange); % Allow time for the image to finish saving
    
    % Delete all other images in the directory
    contents = dir(SLM_dir); % Update our list of files in the directory
    contents = contents(~ismember({contents.name}, {'.', '..','desktop.ini'})); % Remove system files from our results
    for k=1 : size(contents,1) % Scan the file names in the SLM's memory
        if ~strcmp(contents(k).name,nameIm)
            % Delete all files except the one we want
            delete([SLM_dir,contents(k).name]);
        end
    end
end






