classdef PM100D < handle
    % This is a class to control a ThorLabs PM100D Power Meter module.
    % For MatLab R2021a or later
    
    % NOTE:
    %   Before connecting, it may be necessary to use ThorLabs' "Power
    %   Meter Driver Switcher" softwate in order to set the PM100D driver
    %   to "PM100D (NI-VISA)" and NOT "TLPM".
    
    properties
        MinWav = 400; % nm
        MaxWav = 1100; % nm
        Wavelength = 532; % nm
        range = 14e-3; % W
        nAv = 1;
        ShowStatus = 1;
        SN;
        vu;
        ID;
    end
    
    methods (Static)
        function obj = PM100D(SNin)
            % This is the constructor
            % Example: meter = PM100D('P0010557'); % Serial Number = 'P0010557';
            if nargin > 0
                obj.ID = ['USB0::0x1313::0x8078::',SNin,'::0::INSTR'];
                obj.SN = SNin;
                warning('off','instrument:query:unsuccessfulRead');
                % Create a VISA-USB object.
                obj.vu = instrfind('Type', 'visa-usb', 'RsrcName', obj.ID, 'Tag', '');

                % Create the VISA-USB object if it does not exist
                % otherwise use the object that was found.
                if isempty(obj.vu)
                    try
                        obj.vu = visadev(obj.ID); % For MatLab R2020b or earlier
                    catch E
                        switch E.identifier
                            case 'instrument:fopen:opfailed'
                                warning('PM100D failed to connect. It may be necessary to use ThorLabs'' "Power Meter Driver Switcher" softwate in order to set the PM100D driver to "PM100D (NI-VISA)" and NOT "TLPM".');
                                rethrow(E);
                            otherwise
                                rethrow(E);
                        end
                    end
                else
                    fclose(obj.vu);
                    obj.vu = obj.vu(1);
                end
                
                % Get the wavelength limits
                writeline(obj.vu,'CORR:WAV? MIN');
                res = char(readline(obj.vu));
                obj.MinWav = str2double(res);

                writeline(obj.vu,'CORR:WAV? MAX');
                res = char(readline(obj.vu));
                obj.MaxWav = str2double(res);
                
                fprintf('PM: Wavelength limits are: %d - %d nm\n',obj.MinWav, obj.MaxWav);
                
                % Set the default wavelength
                if (obj.Wavelength >= obj.MinWav) && (obj.Wavelength <= obj.MaxWav)
                    s = sprintf('CORR:WAV %g nm',obj.Wavelength);
                elseif obj.MinWav == 700
                    obj.Wavelength = 780;
                    s = sprintf('CORR:WAV %g nm',obj.Wavelength);
                else
                    obj.Wavelength = obj.MinWav;
                    s = sprintf('CORR:WAV %g nm',obj.Wavelength);
                end
                writeline(obj.vu, s);
                pause(0.1);
                writeline(obj.vu,'CORR:WAV?');
                res = char(readline(obj.vu));
                obj.Wavelength = str2double(res);
                fprintf('PM: Default wavelength set to: %d nm\n',obj.Wavelength);
                
                
                % Set the default power range
                cmd = sprintf('POW:RANG:UPP %.2e W',obj.range);
                writeline(obj.vu,cmd);
                pause(0.1)
                writeline(obj.vu, 'POW:RANG:UPP?');
                res = char(readline(obj.vu));
                obj.range = str2double(res);
                fprintf('PM: Default power range set to: %.2e W\n',obj.range);
                
            else
                error('No serial number provided for the power meter.');
            end
            disp(['Power Meter has been connected: ', obj.SN]);
        end
        
    end
    
    methods
        
        function close(obj)
            clear obj.vu;
            disp(['Power Meter has been disconnected: ',obj.SN]);
        end

        function resetConn(obj, pauseTime)
            disp('========= Resetting connection to the Power Meter ========='); beep; pause(0.2); beep;
            clear obj.vu;
            pause(pauseTime);
            % Create a VISA-USB object.
            obj.vu = instrfind('Type', 'visa-usb', 'RsrcName', obj.ID, 'Tag', '');

            % Create the VISA-USB object if it does not exist
            % otherwise use the object that was found.
            if isempty(obj.vu)
                try
                    obj.vu = visadev(obj.ID); % For MatLab R2020b or earlier
                catch E
                    switch E.identifier
                        case 'instrument:fopen:opfailed'
                            warning('PM100D failed to connect. It may be necessary to use ThorLabs'' "Power Meter Driver Switcher" softwate in order to set the PM100D driver to "PM100D (NI-VISA)" and NOT "TLPM".');
                            rethrow(E);
                        otherwise
                            rethrow(E);
                    end
                end
            else
                fclose(obj.vu);
                obj.vu = obj.vu(1);
            end
            disp('============== Power Meter connection reset ===============');
        end
        
        function enableStatusDisplay(obj)
           obj.ShowStatus = 1;
        end
        
        function disableStatusDisplay(obj)
           obj.ShowStatus = 0;
        end
        
        function setAveraging(obj, n)
            cmd = sprintf('SENS:AVER:COUN %d',n);
            writeline(obj.vu, cmd);
            
            writeline(obj.vu, 'SENS:AVER:COUN?');
            res = char(readline(obj.vu));
            obj.nAv = str2double(res);
            if obj.ShowStatus==1, fprintf('PM: Set averaging to: %d\n',obj.nAv); end
            
        end
        
        function setWavelength(obj, Wav)
            if (Wav >= obj.MinWav) && (Wav <= obj.MaxWav)
                obj.Wavelength = Wav;
                s = sprintf('CORR:WAV %g nm',Wav);
                writeline(obj.vu, s);
                pause(0.1);
                writeline(obj.vu,'CORR:WAV?');
                res = char(readline(obj.vu));
                obj.Wavelength = str2double(res);
                if obj.ShowStatus==1, fprintf('PM: Set wavelength to: %d nm\n',obj.Wavelength); end
            else
                error('PM: The wavelength %d nm is out of the range %d - %d nm].',Wav, obj.MinWav, obj.MaxWav);
            end
        end
        
        function res = measure_mW(obj)
            cmd = 'MEASURE:POWER?';
            writeline(obj.vu, cmd);
            res = str2double(char(readline(obj.vu))).*1e3; %mW
            flush(obj.vu);
        end
        
        function out = measureAv_mW(obj, n)
            cmd = 'MEASURE:POWER?';
            pwr = 0;

            for i=1 : n
                writeline(obj.vu, cmd);

                res = str2double(char(readline(obj.vu))).*1e3; %mW
                
                pause(0.01);
                if isnan(res)
                    fprintf('Visa Serial communication issue, wait and try again.\n');
                    beep;pause(0.5);beep;pause(0.5);beep;pause(0.5);beep;
                    pause(1);
                    out = NaN;
                    return;
                end
                
                pwr = pwr + res;
            end
            out = pwr./n;
        end
        
        function res = setRange_mW(obj, rng)
            cmd = sprintf('POW:RANG:UPP %.2e W',rng.*1e-3);
            writeline(obj.vu, cmd);
            
            cmd = 'POW:RANG:UPP?';
            writeline(obj.vu,cmd);
            res = str2double(char(readline(obj.vu))).*1000;
            obj.range = res./1000;
            if obj.ShowStatus==1, fprintf('PM: Set power range to: %d W\n',obj.range); end
        end
        
        function res = getRange_mW(obj)
            cmd = 'POW:RANG:UPP?';
            writeline(obj.vu,cmd);
            res = str2double(char(readline(obj.vu))).*1000;
            obj.range = res./1000;
        end
        
        
        
    end    
    
    
end




