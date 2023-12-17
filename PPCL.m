classdef PPCL < handle
    % Jan-17-2022: Added " < handle" to classdef.
    % This is a class to control the Pure Photonics PPCLs
    
    properties
        MinFreq = 191.5; % THz
        MaxFreq = 196.25; % THz
        MinPwr = 700;  % 100*dB
        MaxPwr = 1350; % 100*dB
        Pwr;        % 100*dB
        WavSet;     % nm
        WavReal;    % nm
        ser;
    end
    
    methods (Static)
        function obj = PPCL(s)
            % This is the constructor
            % Example: laser = PPCL(serialport("COM1",9600))
            if nargin > 0
                obj.ser = s;
            end
        end
        
    end
    
    methods
        
        function On(obj)
           rep = ITLA_command(obj.ser,0x32,0x08,1); % turn on laser 
        end
        
        function Off(obj)
           rep = ITLA_command(obj.ser,0x32,0x00,1); % turn off laser 
        end
        
        function setPwr(obj, power)
            if (power < obj.MinPwr) || (power > obj.MaxPwr)
                error('Power must be between 600 and 1369');
            end
            rep = ITLA_command(obj.ser,0x31,power,1); % set power to (min=600)
            pause(0.1);
            obj.Pwr = power;
        end
        
        function wavRes = setWav(obj, wavelength)
            freq = 299792.458./wavelength;
            
            if (freq < obj.MinFreq) || (freq > obj.MaxFreq)
                error('Wavelength must be between 1527.604 and 1565.495nm');
            end
            
            obj.WavSet = wavelength;
            
            THz = floor(freq); % THz portion of freq
            pGHz = round(1e4.*(freq-THz)); % 0.1*GHz portion of freq
            
            res = ITLA_command(obj.ser,0x32,0,0); % Read the Enable register
            res = ITLA_command(obj.ser,0x32,0,1); % Turn off the laser

            res = ITLA_command(obj.ser,0x35,THz,1);  % Write target THz for Channel 1
            res = ITLA_command(obj.ser,0x36,pGHz,1); % Write target 0.1*GHz for Channel 1

            res = ITLA_command(obj.ser,0x32,0,1); % Turn off the laser (again)

            pause(0.1);
            
            freqRt = ITLA_command(obj.ser,0x35,0,0);  % Read real freq THz
            freqRt = freqRt(end);
            freqRg = ITLA_command(obj.ser,0x36,0,0);  % Read real freq 0.1GHz
            freqRg = (freqRg(end-1).*(2^8)) + freqRg(end);
            freqRes = freqRt + (freqRg./1e4);
            clear freqRt freqRg
            wavRes = 299792.458./freqRes;
            
            obj.WavReal = wavRes;

            res = ITLA_command(obj.ser,0x32,0x08, 1); % turn on laser
            
        end
        
        
        
    end    
    
    
end




