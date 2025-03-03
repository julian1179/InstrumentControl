function [] = newExperiment(cap_dir, exp_num, Fig1, Fig2, pwr, caps, pSLM1angle,SLM1_Scaling, pSLM2angle,SLM2_Scaling, angleQue, angleRef, intCc, queCc, refCc)
%   This function generates the TXT file with all of the relevant
%   experiment information. If the file already exists, an error is
%   returned to prevent accidentally overriding a previous experiment.

    % Check to see if the txt file already exists for this exp_num
    if exist(cap_dir)
        error(strcat('ERROR: Exp', exp_num, ' Folder already exists. Please change the Experiment number.'));
        return
    end
    mkdir(cap_dir) % Make the txt file.

    D = date; % Get today's date
    [~,Day] = weekday(D);

    % Read txt into cell A. This essentially copies the format from Reference_files
    fid = fopen('C:\Users\LAPT\Desktop\Synchronized Experiments\Large experimental data\HOC Research\Captures_3Cam\Auto-calibrated Experiments\Reference_files\Explanation.txt','r');
    i = 1;
    tline = fgetl(fid);
    A{i} = tline;
    while ischar(tline)
        i = i+1;
        tline = fgetl(fid);
        A{i} = tline;
    end
    fclose(fid);
    % Change cell A to include all of our new experiment info.
    A{1} = [Day ', ' date];
    A{3} = ['Reference	= ' Fig1];
    A{4} = ['Query		= ' Fig2];
    A{5} = ['Laser Power	= ' num2str(pwr*1000) ' mW'  ];
    A{6} = ['Average Caps	= ' num2str(caps)];
    A{7} = ['RefSLM Angle	= ' num2str(pSLM1angle) '°'];
    A{8} = ['RefSLM PowScal	= ' num2str(SLM1_Scaling)];
    A{9} = ['QueSLM Angle	= ' num2str(pSLM2angle) '°'];
    A{10} =['QueSLM PowScal	= ' num2str(SLM2_Scaling)];
    A{11} =['IntFPA Xc  = ' num2str(intCc(2))];
    A{12} =['IntFPA Yc  = ' num2str(intCc(1))];
    A{13} =['QueFPA Xc  = ' num2str(queCc(2))];
    A{14} =['QueFPA Yc  = ' num2str(queCc(1))];
    A{15} =['RefFPA Xc  = ' num2str(refCc(2))];
    A{16} =['RefFPA Yc  = ' num2str(refCc(1))];
    A{17} =['QueFPA Angle	= ' num2str(angleQue) '°'];
    A{18} =['RefFPA Angle	= ' num2str(angleRef) '°'];
    %%
    % Write cell A into txt
    fid = fopen(strcat(cap_dir, '\Explanation.txt'),'w');
    for i = 1:numel(A)-1
        fprintf(fid,'%s\n', A{i});
    end
    fclose(fid);
end


