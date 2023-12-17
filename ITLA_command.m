function reply=ITLA_command(sercon,register,data,rw)
%Sends command to laser and gets reply. See manual for full specification
%of commands.
% command: (s,0,0,0) - verification reply [84, 0, 0, 16]
% command (s,2,0,0) - reply : PurePh
% command (s,0x32,0x08,1) - turn on laser
% command (s,0x90,2,1) - switch to whisper mode
% command (s,0x31,power,1) - set power to (min=600)
% command (s,0x42,0,0) - read power (returns 128<<8 when laser is off)
% command (s,0x62,freq,1) - set frequency
% command (s,0x32,0x00,1) - shut down laser
% 
% Clean jump to 193.4145 THz:
%     command (s,0xEA,193,1)  % Write target at 193 THz
%     command (s,0xEB,4145,1) % Write target at 414.5 GHz
%     command (s,0xED,1,1)    % Execute clean jump

    AEA = 11;
    byte2=bitshift(data,-8);
    byte3=data-bitshift(byte2,8);
    byte0=bitor(bitshift(checksum(rw,register,byte2,byte3),4),rw);
    %Sending a string does not work
    write(sercon,[byte0, register, byte2, byte3], "uint8");
%     disp(['sending :',dec2hex(byte0),' ',dec2hex(register),' ',dec2hex(byte2),' ',dec2hex(byte3)])
    pause(0.1);
    ser_res=read(sercon,sercon.NumBytesAvailable, "uint8")'; %% try fscan
    %disp(['recieved from laser ' ser_res])
    %AEA flag raised, get more data
    if (bitand(ser_res(1),3)==2) && (size(ser_res,2)==4)
        bytes_left=bitshift(ser_res(3),8)+ser_res(4);
        disp(['bytes left: ' num2str(bytes_left)])
        ser_res=[];
        while bytes_left>0
            pause(0.1);
            byte0=bitshift(checksum(0,AEA,0,0),4);
            write(sercon,[byte0, AEA, 0, 0], "uint8");
            pause(0.1);
            ser_res_tmp=read(sercon,sercon.NumBytesAvailable, "uint8")';
            disp([ser_res_tmp])
            if size(ser_res_tmp,2)>1
                ser_res=[ser_res ser_res_tmp(end-1)];
                ser_res=[ser_res ser_res_tmp(end)];
                bytes_left=bytes_left-2;
            end
        end
    end
    reply=ser_res;
end


function x=checksum(byte0,byte1,byte2,byte3)
    bip8=bitxor(bitand(byte0,15, 'uint8'), bitxor(byte1, bitxor(byte2, byte3)));
    x=bitxor(bitshift(bitand(bip8,240, 'uint8'),-4),bitand(bip8, 15,'uint8'));
end
