% The PPCL.m file requires the ITLA_command.m file to work.
% This code connects two PurePhotonics PPCL lasers, configures
% them to their respective wavelengths and power, ensures they
% are off, and then turns them on.

clear *
clc

las1558 = PPCL(serialport("COM6", 9600));
las1558.MaxPwr = 1700; % Set max power to 17 dBm
las1558.setPwr(las1558.MaxPwr); % 100x the dBm you want to set.

las1556 = PPCL(serialport("COM7", 9600));
las1556.setPwr(las1556.MaxPwr); % Default Max power is 13.5 dBm.

%%
las1558.Off();
las1556.Off();

%%
pause(2);
res = las1558.setWav(1558.2);
res = las1556.setWav(1556.2);
pause(2);

%%

las1558.On();
las1556.On();


