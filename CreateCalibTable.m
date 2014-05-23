function [ table ] = CreateCalibTable( vals )
%CREATECALIBTABLE Summary of this function goes here
%   Detailed explanation goes here
if nargin<1
    vals = 0:5:255;
end

caughtException = [];
delete(instrfind()); % kludge in case of conflicts?


HW = HardwareParameters();
HW.stereoMode = 0;
HW.stereoTexOffset = [];
HW.usePTBPerPxCorrection = false;
dummyLums = [0:10:250, 255]';
HW.lumCalib = [dummyLums, dummyLums];

[didHWInit, HW] = InitializeHardware(HW);
HW = ScreenCustomStereo(HW, 'Flip', HW.winPtr); % initial flip

meter = PR524();
try
    table = zeros(length(vals),2);
    for i = 1:length(vals)
        curValue = vals(i);
        
        for eye = [0 1]
            HW = ScreenCustomStereo(HW, 'SelectStereoDrawBuffer', ...
                    HW.winPtr, eye);
            Screen('FillRect', HW.winPtr, curValue);
        end
        
        fprintf('Data for %i: ', curValue);
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

