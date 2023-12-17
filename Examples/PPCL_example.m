clear *
clc

las1558 = PPCL(serialport("COM6", 9600));
las1558.MaxPwr = 1700;
las1558.setPwr(las1558.MaxPwr);

las1556 = PPCL(serialport("COM7", 9600));
las1556.MaxPwr = 1700;
las1556.setPwr(las1556.MaxPwr);

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


