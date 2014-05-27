function [ table ] = CreateCalibTable( vals )
%CREATECALIBTABLE Summary of this function goes here
%   Detailed explanation goes here
if nargin<1
    vals = 0:5:255;
end

refreshRate = 120;
%exposureTime = 500; % ms, up to 500? Manual says microseconds, but seems wrong

caughtException = [];

HW = HardwareParameters();
HW.stereoMode = 1;
HW.stereoTexOffset = [];
HW.usePTBPerPxCorrection = false;
dummyLums = [0:10:250, 255]';
HW.lumCalib = [dummyLums, dummyLums];

delete(instrfind()); % kludge in case of conflicts?
meter = PR524();

[didHWInit, HW] = InitializeHardware(HW);
try
    HW = ScreenCustomStereo(HW, 'SelectStereoDrawBuffer', ...
        HW.winPtr, 0); % Just to get something in HW.winPtr
    HW = ScreenCustomStereo(HW, 'Flip', HW.winPtr); % initial flip
    
    % user-defined sync to any strobing backlight ('source frequency')
    % set source freq to multiple of 60 (preferably refresh rate)
    [~] = sendAndRead(meter, 'SS3');
    [~] = sendAndRead(meter, sprintf('SK%i', refreshRate));
    
    %[~] = sendAndRead(meter, sprintf('SE%i', exposureTime));
    
    % Throw away first measurement (inconsistant with all others for some reason)
    [~] = sendAndRead(meter, 'M1', '%i,%i,%f', 4.0);
    
    table = zeros(length(vals),2);
    for i = 1:length(vals)
        curValue = vals(i);
        fprintf('Measuring for %f: ', curValue);
        
        for eye = [0 1]
            HW = ScreenCustomStereo(HW, 'SelectStereoDrawBuffer', ...
                HW.winPtr, eye);
            Screen('FillRect', HW.winPtr, curValue);
        end
        HW = ScreenCustomStereo(HW, 'Flip', HW.winPtr);
        
        pause(0.1)
        data = sendAndRead(meter, 'M1', '%i,%i,%f', 4.0);
        measured = data(3);
        fprintf('%f\n', measured);
        
        table(i,:) = [curValue, measured];
    end
catch e
    caughtException = e;
end

if didHWInit
    HW = CleanupHardware(HW); %#ok<NASGU>
end
delete(meter);

if ~isempty(caughtException); rethrow(caughtException); end;

end

