classdef ELL18 < handle
    % This is a class to control the ThorLabs ELL18 rotation stage
    
    properties
        ShowStatus = 1; % Flag for whether or not to print status
        MinVel = 27;    % Percent
        MaxVel = 100;   % Percent
        HomePos = 0;    % User-adjustable home position
        Address = '0';  % ELL18 address (in case there are multiple ELL's)
        Vel;            % Percent
        Scaling;        % "pulses per rotation" scaling factor. This 
                        % corresponds to the # of pulses required for 360° 
                        % of rotation.
        Pos;            % [deg] Current position
        ser;
    end
    
    methods (Static)
        function obj = ELL18(s) % This is the constructor
            % Example: motor = ELL18(serialport("COM3",9600))
            if nargin > 0
                obj.ser = s;
                configureTerminator(obj.ser,"CR");
            end
        end
        
    end
    
    methods
        
        function Init(obj) % Initialization procedure
            disp('-------------------------------------------');
            disp('------------Initializing ELL18-------------');
            % Request the device's parameters
            writeline(obj.ser, sprintf([obj.Address,'in']));
            rx = readline(obj.ser);

            % The last 8 bits have the "pulses per rotation" scaling factor. This
            % corresponds to the # of pulses required for 360° of rotation.
            endIn = strlength(rx); % end index
            obj.Scaling = msg2double(rx, endIn-7, endIn);
            disp('----------Initialization complete----------');
            disp('-------------------------------------------');
            disp('');
        end
        
        function enableStatusDisplay(obj)
           obj.ShowStatus = 1;
        end
        
        function disableStatusDisplay(obj)
           obj.ShowStatus = 0;
        end
        
        function setHome(obj) % Sets the current position as home.
            if obj.ShowStatus==1, disp('---------------Setting home----------------'); end
            if obj.ShowStatus==1, fprintf('New home set to:   '); end
            obj.getPos();
            obj.HomePos = obj.Pos;
        end
        
        function home(obj) % Goes to 0°
           obj.setPos(0);
        end
        
        function homeAbs(obj) % Goes to the physical 0° position and resets obj.HomePos
            if obj.ShowStatus==1, disp('------------Searching for home-------------'); end
            obj.getPos()
            % Go home
            writeline(obj.ser, sprintf([obj.Address,'ho0']));
            [~] = readline(obj.ser);
            
            td = abs(obj.Pos); % Distance [deg] travelled for time delay calculation
            tp = td .* 0.5./(360.*obj.Vel./100); % Time [s] required to travel td at vel.
            pause(ceil(tp)+0.1);
            
            % Confirm actual position
            writeline(obj.ser, sprintf([obj.Address,'gp']));
            rx = readline(obj.ser);
            endIn = strlength(rx);

            % Check for errors
            if extractBetween(rx,2,4) == [obj.Address,'PO']
                p = msg2double(rx, 5, endIn);
                obj.Pos = p.*360/obj.Scaling;
                obj.HomePos = 0;
                if obj.ShowStatus==1, disp(sprintf('----Homing complete. Current position: %.3f °', obj.Pos)); end
            else
            	if obj.ShowStatus==1, disp(sprintf(['----Homing move-absolute returned error: ',rx])); end
            end
            disp(' ');
        end
        
        function getVel(obj)
            % Request the current velocity
            writeline(obj.ser, sprintf([obj.Address,'gv']));
            rx = readline(obj.ser);
            endIn = strlength(rx);
            obj.Vel = msg2double(rx, endIn-1,endIn);
            if obj.ShowStatus==1, disp(sprintf('Velocity currently set to %d%%', obj.Vel)); end
            pause(0.1);
        end
        
        function setVel(obj, v)
            if obj.ShowStatus==1, disp('-------------Setting velocity--------------'); end
            obj.getVel();
            pause(0.1);

            if obj.Vel ~= v % If the current velocity is different from what we want, change it.
               writeline(obj.ser, sprintf([obj.Address,'sv',dec2hex(v)]));
               rx = readline(obj.ser);
               endIn = strlength(rx);
               % Check for errors
               if hex2dec(extractBetween(rx,endIn-1,endIn)) == 0
                   obj.Vel = v;
                   if obj.ShowStatus==1, disp(sprintf('----Velocity succesfully set to %d%%', v)); end
               else
                   if obj.ShowStatus==1, disp(sprintf(['----Velocity set returned error: ',rx])); end
               end
            end
            disp(' ');
        end
        
        function getPos(obj)
            % Request the current velocity
            writeline(obj.ser, sprintf([obj.Address,'gp']));
            rx = readline(obj.ser);
            endIn = strlength(rx);
            
            p = msg2double(rx, 5, endIn);
            obj.Pos = p.*360/obj.Scaling;
            if obj.ShowStatus==1, disp(sprintf('Current position: %.3f °', obj.Pos-obj.HomePos)); end
            pause(0.1);
        end

        function setPos_raw(obj, p)
            if obj.ShowStatus==1, disp('-------------Setting position--------------'); end

            steps = round(p*obj.Scaling./360); % Conversion from degrees to steps.
            % Move-absolute to the desired position
            writeline(obj.ser, sprintf([obj.Address,'ma',dec2hex(steps,8)]));
            [~] = readline(obj.ser);
            
            % It takes 2s to move 360° at 30% speed. Thus, 0.6s at 100%.
            td = abs(obj.Pos-p); % Distance [deg] travelled for time delay calculation
            tp = td .* 0.5./(360.*obj.Vel./100); % Time [s] required to travel td at vel.
            pause(ceil(tp)+0.1);

            % Confirm actual position
            writeline(obj.ser, sprintf([obj.Address,'gp']));
            rx = readline(obj.ser);
            endIn = strlength(rx);

            % Check for errors
            if extractBetween(rx,2,4) == [obj.Address,'PO']
                p = msg2double(rx, 5, endIn);
                obj.Pos = p.*360/obj.Scaling;
                if obj.ShowStatus==1, disp(sprintf('Moved to position: %.3f °', obj.Pos-obj.HomePos)); end
            else
                if obj.ShowStatus==1, disp(sprintf(['Move-absolute returned error: ',rx])); end
            end 
            disp(' ');
        end
        
        function setPos(obj, p)
            if obj.ShowStatus==1, disp('-------------Setting position--------------'); end
            p = p+obj.HomePos;
            if p>=360
                p = p - 360.*floor(abs(p)./360);
            elseif p<=-360
                p = p+360.*floor(abs(p)./360);
            end
            
            steps = round(p*obj.Scaling./360); % Conversion from degrees to steps.
            % Move-absolute to the desired position
            writeline(obj.ser, sprintf([obj.Address,'ma',dec2hex(steps,8)]));
            [~] = readline(obj.ser);
            
            % It takes 2s to move 360° at 30% speed. Thus, 0.6s at 100%.
            td = abs(obj.Pos-p); % Distance [deg] travelled for time delay calculation
            tp = td .* 0.5./(360.*obj.Vel./100); % Time [s] required to travel td at vel.
            pause(ceil(tp)+0.1);

            % Confirm actual position
            writeline(obj.ser, sprintf([obj.Address,'gp']));
            rx = readline(obj.ser);
            endIn = strlength(rx);

            % Check for errors
            if extractBetween(rx,2,4) == [obj.Address,'PO']
                p = msg2double(rx, 5, endIn);
                obj.Pos = p.*360/obj.Scaling;
                if obj.ShowStatus==1, disp(sprintf('Moved to position: %.3f °', obj.Pos-obj.HomePos)); end
            else
                if obj.ShowStatus==1, disp(sprintf(['Move-absolute returned error: ',rx])); end
            end 
            disp(' ');
        end
        

    end   
end

function num = msg2double(msg, st, fin)
    % Convert from String to Hex to signed int32 to double
    num = double(typecast(uint32(sscanf(extractBetween(msg,st,fin), '%x')), 'int32'));
end




