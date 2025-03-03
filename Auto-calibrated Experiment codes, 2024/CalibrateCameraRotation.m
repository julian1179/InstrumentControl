function [pSLM1angleInt, pSLM2angleInt, pSLM1angleQue, pSLM2angleRef, intCc, queCc, refCc] = CalibrateCameraRotation(SLM1_dir, SLM2_dir, caps, cams, exp_t, calib_im_dir, plotFlag)
    arguments
        % SLM variables
        SLM1_dir = 'Z:\DCIM\';
        SLM2_dir = 'Y:\DCIM\';
        
        % FPA variables
        caps = 20; % Number of captures to average.
        % Cameras used for [Interference, pSLM1(Que), pSLM2(Ref)]
        cams = [4, 3, 5];
        exp_t = [5, 4.4, 2.2]; % [ms]

        % calib_im_dir = 'C:\Users\Julian\Desktop\Large experimental data\HOC Research\Captures_3Cam\Calibration\';
        calib_im_dir = 'C:\Users\LAPT\Desktop\Synchronized Experiments\Large experimental data\HOC Research\Captures_3Cam\Calibration\';
        plotFlag = 0;
    end
    
    % Use this software to 'mount' the pSLMs as drives:
    %   https://www.mtpdrive.com/download.html
    %
    % Registration key for this software:
    % -----BEGIN MTPDRIVE REGISTRATION KEY-----
    % 2iX668EA9ShGdc6KanbtZiONWqSWsMEsKQuxHhwp4R7lKzl8w3BfygpfNX0tpill
    % giU2zFLebWV9j8RWG55TAV/S7t6ug67jFZfdaVQkUeYvQMCEV4fPn/AiInz4EMZ+
    % xcHnbUjWJ1UHmv/Hz+yBzU2jofTbSJ6ot5gMErnqNcdfFOBxIVeqeCXoEPl8JLCm
    % lI3jEDakJKzWX0Kp9ALj2p5ie3HnPkotEEwe1vbPiEmDPVbpb3i2UAzwek8DmdpH
    % NnrcAKtbwwFnglYobWwPOs0s+LX0N50m/o2GHhIBxWjCOvG0SMTBsT3N0YuEq8BN
    % qm+cz8sx0gMYuK2H2LtNIiNB1WshcX5Tmik5E7AKNybCuQuVLFBSkwZH4Nz/2+fq
    % 0T6r/0YlMPKGKZ7c+IU2tPiEmVNxQEFFNmTTQK9IBkldhPP2Rlrlv9ul+eV3/iZY
    % yPMAA7sApp8stRql9EPnJauWaRr87JpkllRDzzKSFtUlG1eGutTG9EzsFK9jKkyo
    % wHe75/HUnJMEmTLRWGeXObpqXxXvhY7muVW0khLV1nQDmpwHLdpMzT4zeyguvkc+
    % XeiEaBu0sv8a9BoOp15W3141wZmSCrAHsRIH6/uHmFa+JcC14sva4WIJFlQoWDrS
    % pON1QQCB9y5SL3SmJ8W1elbB4hDcVUpfhhk6ELtwvyI=
    % -----END MTPDRIVE REGISTRATION KEY-----
    %
    

    tImChange = 2; % Delay time [s] for copying over images to the pSLMs

    
    calib_white = 'White_screen.jpg';
    calib_black = 'Black_screen.jpg';
    calib_grid = 'Calib_grid.bmp';
    % Example for using a custom function to copy an image to the SLM:
    % SLMImLoad(SLM1_dir, calib_im_dir, calib_grid, tImChange)
    
    %% Initialize the cameras
    disp('-------------------------Connecting to FPAs-------------------------');
    camInt = ZeluxFPA(cams(1), 0);             camQue = ZeluxFPA(cams(2), 0);              camRef = ZeluxFPA(cams(3), 0);
    
    camInt.init();                           camQue.tlCameraSDK = camInt.tlCameraSDK;  camRef.tlCameraSDK = camInt.tlCameraSDK;
    
                                             camQue.init();                            camRef.init();
    
    camInt.open();                           camQue.open();                            camRef.open();
    
    camInt.setExpT(exp_t(1));                camQue.setExpT(exp_t(2));                 camRef.setExpT(exp_t(3));

    disp('---------------------------FPAs Connected---------------------------');
    clc
    %% ------------------------- SLM1 rotation angle --------------------------
    
    % % Uncomment to generate a fresh calibration grid
    % imwrite(generateCalibGrid(14,0), [calib_im_dir,calib_grid]);
    % pause(1.5);
    
    % The interference camera will tell us how much we need to rotate the image
    % at the SLM to get the output to be aligned to the axes.
    SLMImLoad(SLM2_dir, calib_im_dir, calib_black, tImChange); % Set SLM2 to a blank screen
    SLMImLoad(SLM1_dir, calib_im_dir, calib_grid, tImChange);  % Set SLM1 to the calibration grid
    im1 = camInt.capAverage(caps);
    % figure;    imagesc(log(im1)); axis image;
    [pSLM1angleInt, ~] = getRotation(im1);
    
    % Create a corrected grid and validate that the angle correction fixes the
    % issue.
    grid_corrected = generateCalibGrid(14,-pSLM1angleInt);
    imwrite(grid_corrected, [calib_im_dir,'temp_calib_grid-pSLM1.bmp']);
    pause(1.5);
    SLMImLoad(SLM1_dir, calib_im_dir, 'temp_calib_grid-pSLM1.bmp', tImChange);  % Set SLM1 to the new calibration grid
    im2 = camInt.capAverage(caps);
    [pSLM1angle2, intCc1] = getRotation(im2);
    
    fprintf('SLM1 on int_cam: Initial angle: %.4f°.        After correction: %.4f°\n', pSLM1angleInt, pSLM1angle2);
    if plotFlag
        figure;
            imagesc(im2); axis image; set(gca, 'YDir', 'normal'); 
            clim([0 1023]); title('Int_{cam} using pSLM_1 with rotated calibration grid');
            drawcrosshair('Position', [size(im1,2)/2 size(im1,1)/2], 'linewidth', 1, 'Color','y');
    end
    
    % ----------------- SLM1 Magnitude camera rotation angle ------------------
    % After rotating the image at the SLM, we check the magnitude camera and
    % apply a rotation to the output to get it to also be aligned at the axes.
    im1 = camQue.capAverage(caps);
    [pSLM1angleQue, queCc] = getRotation(im1);
    fprintf('SLM1 on que_cam: correction angle: %.4f°\n\n', pSLM1angleQue);
    
    im2 = imrotate(im1, -pSLM1angleQue, 'bilinear', 'crop');
    if plotFlag
        figure;
        imagesc(im2); axis image; set(gca, 'YDir', 'normal'); 
        clim([0 1023]); title('Corrected Que_{cam} using rotated calibration grid');
        drawcrosshair('Position', [size(im1,2)/2 size(im1,1)/2], 'linewidth', 1, 'Color','y');
    end
    
    %% ------------------------- SLM2 rotation angle --------------------------
    
    
    % The interference camera will tell us how much we need to rotate the image
    % at the SLM to get the output to be aligned to the axes.
    SLMImLoad(SLM1_dir, calib_im_dir, calib_black, tImChange); % Set SLM1 to a blank screen
    SLMImLoad(SLM2_dir, calib_im_dir, calib_grid, tImChange);  % Set SLM2 to the calibration grid
    im1 = camInt.capAverage(caps);
    % figure;    imagesc(log(im1)); axis image;
    [pSLM2angleInt, ~] = getRotation(im1);
    
    % Create a corrected grid and validate that the angle correction fixes the
    % issue.
    grid_corrected = generateCalibGrid(14,-pSLM2angleInt);
    imwrite(fliplr(grid_corrected), [calib_im_dir,'temp_calib_grid-pSLM2.bmp']);
    pause(1.5);
    SLMImLoad(SLM2_dir, calib_im_dir, 'temp_calib_grid-pSLM2.bmp', tImChange);  % Set SLM2 to the new calibration grid
    im2 = camInt.capAverage(caps);
    [pSLM2angle2, intCc2] = getRotation(im2);
    
    fprintf('SLM2 on int_cam: Initial angle: %.4f°.        After correction: %.4f°\n', pSLM2angleInt, pSLM2angle2);
    if plotFlag
        figure;
        imagesc(im2); axis image; set(gca, 'YDir', 'normal'); 
        clim([0 1023]); title('Int_{cam} using pSLM_2 with rotated calibration grid');
        drawcrosshair('Position', [size(im1,2)/2 size(im1,1)/2], 'linewidth', 1, 'Color','y');
    end
    
    % ----------------- SLM2 Magnitude camera rotation angle ------------------
    % After rotating the image at the SLM, we check the magnitude camera and
    % apply a rotation to the output to get it to also be aligned at the axes.
    im1 = camRef.capAverage(caps);
    [pSLM2angleRef, refCc] = getRotation(im1);
    fprintf('SLM2 on ref_cam: correction angle: %.4f°\n\n', pSLM2angleRef);
    
    im2 = imrotate(im1, -pSLM2angleRef, 'bilinear', 'crop');
    if plotFlag
        figure;
        imagesc(im2); axis image; set(gca, 'YDir', 'normal'); 
        clim([0 1023]); title('Corrected output of Ref_{cam} using rotated calibration grid');
        drawcrosshair('Position', [size(im1,2)/2 size(im1,1)/2], 'linewidth', 1, 'Color','y');
    end

    intXc = round(mean([intCc1(2), intCc2(2)]));
    intYc = round(mean([intCc1(1), intCc2(1)]));
    intCc = [intYc, intXc];
    
    %%
    disp('-------------------------Disconnecting FPAs for camera rotation-------------------------');
    camInt.close();  camQue.close();  camRef.close();
    
    camInt.closeSDK();
    disp('---------------------------FPAs Disconnected for camera rotation------------------------');
end


%% ========================================================================
%  ========================== Functions and such ==========================
%  ========================================================================

function im = generateCalibGrid(grid_square_sz, rotation)
%     grid_square_sz = 14;
    num_blocks = 5;
    line = repmat([1,0],[1,num_blocks]);
    line = line(1:end-1);
    grid = uint8(zeros(length(line)));
    flag = 1;
    for i=1:length(line)
        if flag
            grid(i,:) = line.*255;
            flag = 0;
        else
            flag = 1;
        end
    end
    grid = imresize(grid,grid_square_sz,'nearest');
    % figure; imagesc(grid); axis image;
    
    if grid_square_sz^2 * num_blocks^2 ~= sum(grid(:)./255)
        error('Something went wrong with the grid definition.');
    end
    grid = imrotate(grid,45+rotation, 'bilinear');
    
    sz2 = length(grid);
    im = uint8(zeros(480, 854));
    im(240-floor(sz2/2) : 240+round(sz2/2)-1  ,  427-floor(sz2/2) : 427+round(sz2/2)-1) = grid;
    % figure; imagesc(im); axis image;
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

function [angle_rot, Cc] = getRotation(im)
    % % Find the approximate location of the center peak
    im_blur = imgaussfilt(im,2); % Blur the image to minimize the effect of noise
    [~, ind] = max(im_blur(:));
    [yc,xc] = ind2sub(size(im_blur),ind);
    % Extract the center grid.
    half_window = 200;
    im_extr = im_blur(yc-half_window:yc+half_window-1, xc-half_window:xc+half_window-1);
    % figure;    imagesc(log(im_extr)); axis image;
    
    
    % Find the 9 primary peaks of the grid using a custom function.
    pk_locs = find9Peaks2D(im_extr, 20);
    
    % A more accurate center position can be found as the average of the
    % locations of the peaks in the grid.
    yc_av = round(mean(pk_locs(:,1)));
    xc_av = round(mean(pk_locs(:,2)));
    
    % Update the center and peak positions to include the correction.
    yc = yc + yc_av-half_window;
    xc = xc + xc_av-half_window;
    Cc = [yc,xc];
    im_extr = im_blur(yc-half_window:yc+half_window-1, xc-half_window:xc+half_window-1);
    pk_locs = find9Peaks2D(im_extr, 20);
%     figure;
%         imagesc((im_extr)); axis image; set(gca, 'YDir', 'normal');
%         clim([0 1023]); title('Cropped blurred original image');
%         drawcrosshair('Position', [200 200], 'linewidth', 1, 'Color','y');
    
    
    % Find the rotation angle of the reference grid using a custom function.
    % This function will check the relative rotation of various points on the
    % grid and return the average value.
    angle_rot = findGridRotation(pk_locs);
    
end

function [pks] = find9Peaks2D(im, block_rad)
% Find the 9 peaks of the grid. MatLab's "findpeaks()" function doesn't
% work for 2D data. Thus, a quick solution is to find the maximum of the
% blurred image, note it down as a peak, then block out the local region
% and find the next maximum.
    n = 9;
    pks = zeros([n,2]);
    for i = 1 : n
        [~, ind] = max(im(:));
        [yc,xc] = ind2sub(size(im),ind);
        pks(i,:) = [yc,xc];
        im(yc-block_rad:yc+block_rad-1 , xc-block_rad:xc+block_rad-1) = 0;
    end

%     figure;    imagesc((im)); axis image; title('From findNPeaks2D() after scanning');
end


function angle = findGridRotation(pk_locs)
% This function will check the relative rotation of various points on the
% grid and return the average value.

    % Sort the peaks by x-value to identify pairs of peaks that are aligned
    % vertically (i.e., have similar x-values).
    [x_pks, ind] = sort(pk_locs(:,2));
    y_pks = pk_locs(ind,1);
    pk_locs = [y_pks,x_pks];
    y_pairs_bot = [pk_locs(2,:);pk_locs(4,:);pk_locs(7,:)];
    y_pairs_top = [pk_locs(3,:);pk_locs(6,:);pk_locs(8,:)];
    angle_yPairs = atand((y_pairs_top(:,2) - y_pairs_bot(:,2)) ./ (y_pairs_top(:,1) - y_pairs_bot(:,1)) );
    
    % Sort the peaks by y-value to identify pairs of peaks that are aligned
    % horizontally (i.e., have similar y-values).
    [y_pks, ind] = sort(pk_locs(:,1));
    x_pks = pk_locs(ind,2);
    pk_locs = [y_pks,x_pks];
    x_pairs_right = [pk_locs(2,:);pk_locs(4,:);pk_locs(7,:)];
    x_pairs_left = [pk_locs(3,:);pk_locs(6,:);pk_locs(8,:)];
    angle_xPairs = -atand((x_pairs_right(:,1) - x_pairs_left(:,1)) ./ (x_pairs_right(:,2) - x_pairs_left(:,2)) );

    % The final angle estimate is the average of the x and y estimates
    angle_estimates = [angle_yPairs;angle_xPairs];
    angle = mean(angle_estimates);
end







