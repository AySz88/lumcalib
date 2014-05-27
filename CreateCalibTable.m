function [ table ] = CreateCalibTable( vals )
%CREATECALIBTABLE Auto-measures luminance at a range of displayed values
%   Detailed explanation goes here
if nargin<1
    vals = 0:5:255;
end

% Either an LCD backlight's strobe rate or a CRT's actual refresh rate
% Usually a multiple of 60 and/or the refresh rate; use [] for auto-sync
strobeRate = [];

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
    
    % Set sync settings
    if isempty(strobeRate)
        % Use auto-sync
        
        % HACK For some reason actually sending the command causes problems
        % so just don't specify (defaults to auto-sync)
        %[~] = sendAndRead(meter, 'SS1');
    else
        % Manually set sync frequency
        [~] = sendAndRead(meter, 'SS3');
        [~] = sendAndRead(meter, sprintf('SK%i', strobeRate));
    end
    
    % Throw away first measurement (can be inconsistant)
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

