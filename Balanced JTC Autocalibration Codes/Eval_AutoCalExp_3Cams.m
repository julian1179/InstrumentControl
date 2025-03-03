% This code uses real measurements of the HOC to calculate the final (Sf)
% signal. It then plots the result for simple visual evaluation.
%

close all
clear *
clc

% profile on % Used to analyze the runtime of this code. Must also add 'profile view' to the end of the code

% base_dir = 'C:\Users\LAPT\Desktop\Synchronized Experiments\Large experimental data\HOC Research\Captures_3Cam\Auto-calibrated Experiments\'; % Base directory for the experiments
base_dir = 'C:\Users\Julian\Desktop\Large experimental data\HOC Research\Captures_3Cam\Auto-calibrated Experiments\'; % Base directory for the experiments
exp_num = '101';

% Select the directory for the experiment.
exp_dir = [base_dir, 'Exp', exp_num,'\'];
% Read the experiment CSV
expList = readtable([exp_dir,'Exp',exp_num,'_inputList.csv'],"Delimiter","comma");


showPlots = 1; % 1 == show plots. 0 == don't show plots
FPA_Coords = 0; % if 1, the plots will have coordinates based on the FPA. Otherwise, just pixel values.
showS3 = 0; % 1 == show S3 signal. 0 == don't show
mesh_or_imagesc = 1; % 0 = mesh     1 = imagesc
JTC_compare = 0; % 1 == compute JTC equivalent output for comparison

S3_save = 0; % Set to 1 to save S3 as an image at the default location with the default name.
scale = sqrt(2e8); %Scales the figure. zlim([0 scale]). Set to 0 to turn off.
lim = 0; % for Sfl. Useful to ignore DC spike. Set to 0 to turn off.

Plot_Int_or_Mag = 1; % 0 == Plot |Sf|²         1 == Plot |Sf|
save_output = 0; % Set to 1 to save the output to an image file at the default location. This is affected by the "Plot_Int_or_Mag" variable.

corrLoc = 0; % 0 == Plot the whole output. if == [y, x] will only plot the correlation
% corrLoc = [1134, 2039]; %  Exp1 - Exp5
% corrLoc = [874, 2563]; %  Exp6
% corrLoc = [874, 2529]; %  Exp7 -
% corrLoc = [2327, 670]; % Exp100 (Aarushi)
corrLoc = [2350, 650]; % Exp101 (Aarushi)

corrWin = 500;
corrWin = 1200;

nPow = 0; % Normalizes corrPow to this value. Set to 0 to turn off.
% nPow = 2.136e+13; % Exp2 Corr1
% nPow = 7.705e+12; % Exp3 Corr1
% nPow = 7.289e+12; % Exp4 Corr1
% nPow = 6.817e+14; % Exp4 Corr1, S3_scaling = [-46.9544 208.0456];
% nPow = 5.369e+12; % Exp6 Corr1
% nPow = 4.666e+14; % Exp6 Corr1 S3_scaling = [-46.2874 208.7126];
% nPow = 5.376e+12; % Exp6 Corr1, S3 rescaled(0,255) and rounded
% nPow = 9.296e+12; % Exp7 Corr1
% nPow = 4.632e+12; % Exp100 Corr1 (Aarushi)
% nPow = 1.973e+12; % Exp8 Corr2
% nPow = 3.586e+11; % Exp9 Corr5 - Measurements were scaled prior to saving
% nPow = 9.244e+11; % Exp10 Corr5

nZ = 0; % Normalizes Z to this value. Set to 0 to turn off.
% nZ = 1.349e+10; % Exp2 Corr1
% nZ = 1.091e+09; % Exp3 Corr1
% nZ = 1.333e+09; % Exp4 Corr1
% nZ = 1.707e+12; % Exp4 Corr1, S3_scaling = [-46.9544 208.0456];
% nZ = 1.389e+09; % Exp6 Corr1
% nZ = 1.239e+12; % Exp6 Corr1 S3_scaling = [-46.2874 208.7126];
% nZ = 1.404e+09; % Exp6 Corr1, S3 rescaled(0,255) and rounded
% nZ = 1.339e+09; % Exp7 Corr1
% nZ = 7.958e+08; % Exp100 Corr1 (Aarushi)
% nZ = 5.038e+08; % Exp8 Corr2
% nZ = 4.291e+07; % Exp9 Corr5 - Measurements were scaled prior to saving
% nZ = 1.242e+08; % Exp10 Corr5

% nPow = 8.187e+15;
% nZ = 9.203e+11;

S3_scaling = 0; % Rescales S3 according to these values. [min(S3_ref(:)), max(S3_ref(:))]
% S3_scaling = [-46.9544 208.0456]; % Exp4 Corr1
% S3_scaling = [-46.2874 208.7126]; % Exp6 Corr1
S3_scaling = 'fit'; % S3 = round(rescale(S3,0,255));

% nZ =  0;
% nPow = 0;


for i = [3]%1: height(expList)
    corrNum = num2str(i);
    FigRef = expList.Ref{i};
    FigQue = expList.Que{i};

    cap_dir = [exp_dir, 'Corr', corrNum,'\'];
    
    % Read 'Explanation.txt' for experiment information
    [Fig1, Fig2, pwr, caps, pSLM1angle,SLM1_Scaling, pSLM2angle,SLM2_Scaling, angleQue, angleRef, intCc, queCc, refCc] = getExplanation(cap_dir);

    %--------------------------------------------------------------------------
    %Ref = double(imread(strcat(cap_dir, B1cam, 'Ref.tif')));
    %Que = double(imread(strcat(cap_dir, B2cam, 'Ref.tif')));
    
    % Read captures
    Int = double(im2gray(imread(strcat(cap_dir, corrNum, '.Int.png'))));
    Que = double(im2gray(imread(strcat(cap_dir, corrNum, '.Que-', FigQue(1:end-4), '.png'))));
    Ref = double(im2gray(imread(strcat(cap_dir, corrNum, '.Ref-', FigRef(1:end-4), '.png'))));
    
    
    window = 800;

    % Center the images
    Int = Int(intCc(1)-window/2 : intCc(1)+window/2 -1, intCc(2)-window/2 : intCc(2)+window/2 -1);
    Que = imrotate(Que, -angleQue, 'bilinear', 'crop');
    Que = Que(queCc(1)-window/2 : queCc(1)+window/2 -1, queCc(2)-window/2 : queCc(2)+window/2 -1);
    Ref = imrotate(Ref, -angleRef, 'bilinear', 'crop');
    Ref = Ref(refCc(1)-window/2 : refCc(1)+window/2 -1, refCc(2)-window/2 : refCc(2)+window/2 -1);

    n1 = size(Int,1); % y
    n2 = size(Int,2); % x    
    
    L1 = 2*n1 - 1; % size on Y
    L2 = 2*n2 - 1; % Size on X

    %%
    im = {Int, Que, Ref};
    imOrder = ['Int'; 'Que'; 'Ref'];

    %% Calculate Sf

    S3 = Int - Que - Ref; % |Mr+Mq|²-|Mr|²-|Mq|² = Mr*·Mq + Mr·Mq*
    S3_JTC = Int; % |Mr+Mq|² =|Mr|² + |Mq|² + Mr*·Mq + Mr·Mq*

    if any(S3_scaling ~= 0) && (length(S3_scaling)==2) % If S3 is to be rescaled
        S3 = 127 + 127.*S3./max(abs(S3_scaling));
        S3(S3>255) = 255;
        S3(S3<0) = 0;
        S3 = round(S3);
        
        S3_JTC = 127 + 127.*S3_JTC./max(abs(S3_scaling));
        S3_JTC(S3_JTC>255) = 255;
        S3_JTC(S3_JTC<0) = 0;
        S3_JTC = round(S3_JTC);
    elseif strcmpi(S3_scaling, 'fit')
        S3 = round(rescale(S3,0,255));
        S3_JTC = round(rescale(S3_JTC,0,255));
    end

    if showS3
        figure;
            imagesc(S3);
%             clim([0, 255]);
            axis equal tight;
            xlim([350, 450]);
            ylim([350, 450]);
            title('S_3');
            colorbar
        if JTC_compare
            figure;
                imagesc(S3_JTC);
%                 clim([0, 255]);
                axis equal tight;
                xlim([350, 450]);
                ylim([350, 450]);
                title('S_3 JTC');
                colorbar
            end
    end
    
    % Attempt to remove DC spike: Make S3 have a mean value of 0 (so DC=0)
    S3 = S3 - mean(S3(:));
    S3_JTC = S3_JTC - mean(S3_JTC(:));

    if S3_save==1 % S3 can be saved to be projected on an SLM and FT'd in the optical domain.
        SLM_Size = [1080,1920];
        S3_hlfWindow = 100;
        S3_center = length(S3)/2;
        S3_scaling = floor(min(SLM_Size)./(2*S3_hlfWindow));
        S3_hlfSize = S3_scaling*S3_hlfWindow;

        S3_zoom = S3(S3_center-S3_hlfWindow:S3_center+S3_hlfWindow-1,S3_center-S3_hlfWindow:S3_center+S3_hlfWindow-1);
        S3_zoom = imresize(S3_zoom,S3_scaling,'nearest');
        
        % Optional Tukey Window
        S3_zoom = round(S3_zoom.*tukeywin(length(S3_zoom),0.25).*tukeywin(length(S3_zoom),0.25)');

        % Optional Radial Tukey Window
%         for r=1:sqrt()

        S3_screen = zeros(SLM_Size);
        S3_screen(SLM_Size(1)/2 -S3_hlfSize:SLM_Size(1)/2 +S3_hlfSize-1, SLM_Size(2)/2 -S3_hlfSize:SLM_Size(2)/2 +S3_hlfSize-1) = S3_zoom;
        
        % Optional: Use this version of S3 for the simulation
%         S3 = S3_screen;

%         S3_loc= strcat(cap_dir, exp_num, '_S3_SLM_tukey.png');
%         imwrite(uint8(S3_screen),gray(256), S3_loc);
%         fprintf('Image has been saved to: %s\n',S3_loc);
        clear S3_zoom S3_screen
    end
    %%

    if any(S3_scaling ~= 0) && (length(S3_scaling)==2)
        S3padded = S3 - 127;
    else
        S3padded = S3;
    end
%     S3padded = padarray(S3,size(S3)./2,0,'both');
    
    n = 8*length(S3padded) -1;
    Sf = fftshift(fft2(S3padded,n,n));
    Sfa = abs(Sf).^2;
    %DC block
    DC_win = 1600;
    Sfa(floor(n/2)- DC_win/2:floor(n/2)+ DC_win/2 -1, floor(n/2)- DC_win/2:floor(n/2)+ DC_win/2 -1) = 0;

    if JTC_compare
        Sf_JTC = fftshift(fft2(S3_JTC,n,n));
        Sfa_JTC = abs(Sf_JTC).^2;
        %DC block
        Sfa_JTC(floor(n/2)- DC_win/2:floor(n/2)+ DC_win/2 -1, floor(n/2)- DC_win/2:floor(n/2)+ DC_win/2 -1) = 0;
    end

    % Make Sfa 50% smaller to simplify plotting and such
    % REMOVE FOR PAPERS
    Sfa = imresize(Sfa,0.5,'nearest');
    if JTC_compare; Sfa_JTC = imresize(Sfa_JTC,0.5,'nearest'); end

%     p = -4 : 2*4/size(Sfa,2): 4 - (2*4/size(Sfa,2));
%     th = -360 : 2*360/size(Sfa,1): 360- (2*360/size(Sfa,1));
    y = linspace(-size(Sfa,1)/2,size(Sfa,1)/2, size(Sfa,1));
    x = linspace(-size(Sfa,2)/2,size(Sfa,2)/2, size(Sfa,2));
    % For real-world physical position of pixel values
    SLM_pixel_length = 5.4e-6; % [m]
    Fs = 1./SLM_pixel_length; % [1/m]
    y_SLMphys = y.*SLM_pixel_length; % [m]
    x_SLMphys = x.*SLM_pixel_length; % [m]
    fy = y.*Fs./length(y);
    fx = x.*Fs./length(x);

    if any(corrLoc ~=0) && (length(corrLoc)==2)
        corr_yC = corrLoc(1);
        corr_xC = corrLoc(2);
        filter_y = zeros(size(y));
        filter_y(corr_yC- corrWin/2 : corr_yC+ corrWin/2 -1) = 1;
        filter_y = (filter_y==1);
        filter_x = zeros(size(x));
        filter_x(corr_xC- corrWin/2 : corr_xC+ corrWin/2 -1) = 1;
        filter_x = (filter_x==1);

        Sfa = Sfa(filter_y,filter_x);
        if JTC_compare; Sfa_JTC = Sfa_JTC(filter_y,filter_x); end

        y = y(filter_y);        fy = fy(filter_y);
        x = x(filter_x);        fx = fx(filter_x);
    end

    
    mSf = max(Sfa(:));
    corrPOW = sum(Sfa(:));
    if JTC_compare
        mSf_JTC = max(Sfa_JTC(:));
        corrPOW_JTC = sum(Sfa_JTC(:));
    end
    
    if nZ ~= 0
        Sfa = Sfa./nZ;
        mSf = mSf./nZ;
        if JTC_compare
            Sfa_JTC = Sfa_JTC./nZ;
            mSf_JTC = mSf_JTC./nZ;
        end
    end

    if nPow ~= 0
        corrPOW = corrPOW./nPow;
        if JTC_compare; corrPOW_JTC = corrPOW_JTC./nPow; end
    end
    
    if lim ~= 0 % (optional) Cut off anything beyond 'lim'.
        Sfa(Sfa > lim) = lim;
        if JTC_compare; Sfa_JTC(Sfa_JTC > lim) = lim; end
        fprintf('Result cut off at lim = %.1e\n',lim);
    end
    
    fprintf('Exp#: %s, corr#: %s, Ref: %s,          Que: %s\n', exp_num, corrNum, FigRef, FigQue);
    if mSf >99 || mSf < 0.01
        fprintf('           Maximum value of |Sf|^2 = %0.3e', mSf);
    else
        fprintf('           Maximum value of |Sf|^2 = %0.3f', mSf);
    end

    if corrPOW >99 || corrPOW < 0.01
        fprintf('    Correlation Power = %0.3e\n',corrPOW);
    else
        fprintf('    Correlation Power = %0.3f\n',corrPOW);
    end

    if JTC_compare
        if mSf >99 || mSf < 0.01
            fprintf('           JTC: Max value of |Sf|^2 = %0.3e', mSf_JTC);
        else
            fprintf('           JTC: Max value of |Sf|^2 = %0.3f', mSf_JTC);
        end
    
        if corrPOW >99 || corrPOW < 0.01
            fprintf('    JTC: Correl Power = %0.3e\n', corrPOW_JTC);
        else
            fprintf('    JTC: Correl Power = %0.3f\n', corrPOW_JTC);
        end
    end
    fprintf('-----------\n');


    %% Plot
    if Plot_Int_or_Mag == 1
        % NOT PHYSICAL, ONLY FOR VISUALIZATION
        warning('Plotting |Sf|. Recall that experiments actually yield |Sf|².');
        Sfa = sqrt(Sfa);
        if JTC_compare; Sfa_JTC = sqrt(Sfa_JTC); end
    end

    % For real-world phyiscal position of pixel values
    FPA_pixel_length = 3.45e-6; % [m]
    focal_length = 150e-3; % [m]
    wavelength = 532e-9; % [m]
    
    y_FPAphys = fy.*wavelength.*focal_length;
    x_FPAphys = fx.*wavelength.*focal_length;

    y_FPA = y_FPAphys./FPA_pixel_length;
    x_FPA = x_FPAphys./FPA_pixel_length;
    
    if showPlots
        fig_Sfa = figure; % Show final "Sf" result
            set(fig_Sfa, 'color', 'w');
            if (mesh_or_imagesc == 0)
                if FPA_Coords
                    mesh(x_FPA, y_FPA, Sfa);
                else
                    mesh(Sfa);
                end
            elseif (mesh_or_imagesc == 1)
        %         imagesc(p, th, Sfa);
                if FPA_Coords
                    imagesc(x_FPA, y_FPA, Sfa); axis equal tight;
                else
                    imagesc(Sfa); axis equal tight;
                end
            else
                error('invalid mesh_or_imagesc value');
            end
            axis('tight');
%             xlabel('p [px]'); ylabel('th [px]');
            xlabel('x [px]'); ylabel('y [px]');
            zlabel('[A.U.]');

            if scale~=0
                if (mesh_or_imagesc == 0)
                    zlim([0 scale]);
                elseif (mesh_or_imagesc == 1)
                    caxis([0 scale]);
                end
            end

            if (mSf > 100) || (mSf < 0.01)
                title({strrep([FigRef, ' vs ', FigQue],'_','-'),['BJTC: exp-',exp_num,' corr-',corrNum],...
                    sprintf('Correlation Peak: %0.3e ', mSf)}); 
                axis('tight'); xlabel('x'); ylabel('y');
            else
                title({strrep([FigRef, ' vs ', FigQue],'_','-'),['BJTC: exp-',exp_num,' corr-',corrNum],...
                    sprintf('Correlation Peak: %0.3f ', mSf)}); 
            end
        
        if JTC_compare
            fig_Sfa = figure; % Show final "Sf" result
                set(fig_Sfa, 'color', 'w');
                if (mesh_or_imagesc == 0)
                    if FPA_Coords
                        mesh(x_FPA, y_FPA, Sfa_JTC);
                    else
                        mesh(Sfa_JTC);
                    end
                elseif (mesh_or_imagesc == 1)
            %         imagesc(p, th, Sfa);
                    if FPA_Coords
                        imagesc(x_FPA, y_FPA, Sfa_JTC); axis equal tight;
                    else
                        imagesc(Sfa_JTC); axis equal tight;
                    end
                else
                    error('invalid mesh_or_imagesc value');
                end
                axis('tight');
%                 xlabel('p [px]'); ylabel('th [px]');
                xlabel('x [px]'); ylabel('y [px]');
                zlabel('[A.U.]');
    
                if scale~=0
                    if (mesh_or_imagesc == 0)
                        zlim([0 scale]);
                    elseif (mesh_or_imagesc == 1)
                        caxis([0 scale]);
                    end
                end
    
                if (mSf > 100) || (mSf < 0.01)
                    title({strrep([FigRef, ' vs ', FigQue],'_','-'),['JTC: exp-',exp_num,' corr-',corrNum],...
                        sprintf('Correlation Peak: %0.3e ', mSf_JTC)}); 
                    axis('tight'); xlabel('x'); ylabel('y');
                else
                    title({strrep([FigRef, ' vs ', FigQue],'_','-'),['JTC: exp-',exp_num,' corr-',corrNum],...
                        sprintf('Correlation Peak: %0.3f ', mSf_JTC)}); 
                end
        end
    end

    if save_output
        if nZ == 0
            error('Output cannot be saved without first setting nZ.');
        end
        if ~exist([exp_dir,'Sfa_Results\'],'dir')
            mkdir([exp_dir,'Sfa_Results\']);
        end
        
        Sfa_save = Sfa.*2^14;
        if any(Sfa_save>2^16 -1)
            warning('  Value of Sfa has been clipped at 2^16 -1');
            Sfa_save(Sfa_save>2^16 -1) = 2^16 -1;
        end

        output_loc= [exp_dir,'Sfa_Results\',corrNum,'_Sfa_output-',FigQue(1:end-4),'.png'];
        imwrite(uint16(Sfa_save), output_loc, 'bitdepth', 16);
        fprintf('           Image has been saved to: %s\n',output_loc);
    end

end
% profile viewer % Used to analyze the runtime of this code

beep; pause(0.75); beep;













