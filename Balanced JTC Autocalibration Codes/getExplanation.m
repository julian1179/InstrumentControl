function [Fig1, Fig2, pwr, caps, pSLM1angle,SLM1_Scaling, pSLM2angle,SLM2_Scaling, angleQue, angleRef, intCc, queCc, refCc] = getExplanation(cap_dir)
    % Opens the 'Explanation.txt' file for a 3-cam HOC experiment
    % and extracts specific info about it.
    %

    fid = fopen(strcat(cap_dir,'Explanation.txt'),'r');
    i = 1;
    tline = fgetl(fid);
    A{i} = tline;
    while ischar(tline)
        i = i+1;
        tline = fgetl(fid);
        A{i} = tline;
    end
    fclose(fid);
    A;
    Fig1 = A{3}(13:end);
    Fig2 = A{4}(10:end);
    pwr = str2double(A{5}(15:end-3))/1000;
    caps = str2double(A{6}(16:end));

    pSLM1angle = str2double(A{7}(16:end-1));
    SLM1_Scaling = str2double(A{8}(18:end));

    pSLM2angle = str2double(A{9}(16:end-1));
    SLM2_Scaling = str2double(A{10}(18:end));

    intXc = str2double(A{11}(13:end));
    intYc = str2double(A{12}(13:end));

    queXc = str2double(A{13}(13:end));
    queYc = str2double(A{14}(13:end));

    refXc = str2double(A{15}(13:end));
    refYc = str2double(A{16}(13:end));

    angleQue = str2double(A{17}(16:end-1));
    angleRef = str2double(A{18}(16:end-1));

    intCc = [intYc,intXc];
    queCc = [queYc,queXc];
    refCc = [refYc,refXc];
  

end