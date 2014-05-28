function [ table, fit ] = CalcBitstealingContribs( nSamples, sampleCenter, variation )
%CALCBITSTEALINGCONTRIBS Summary of this function goes here
%   Detailed explanation goes here

if nargin < 1 || isempty(nSamples)
    nSamples = 100;
end
if nargin<2 || isempty(sampleCenter)
    sampleCenter = 100;
end
if nargin<3 || isempty(variation)
    variation = 3;
end

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
    
    % Throw away first measurement (can be inconsistant)
    [~] = sendAndRead(meter, 'M1', '%i,%i,%f', 4.0);
    
    startTime = now; % just for easier reading later
    bits = round((rand(nSamples,3)-0.5)*3*variation);
    samples = bits + sampleCenter;
    table = zeros(size(samples) + [0 3]);
    for i = 1:nSamples
        curSample = samples(i,:);
        fprintf('[%i,%i,%i] ', curSample(1), curSample(2), curSample(3));
        
        for eye = [0 1]
            HW = ScreenCustomStereo(HW, 'SelectStereoDrawBuffer', ...
                HW.winPtr, eye);
            Screen('FillRect', HW.winPtr, curSample);
        end
        HW = ScreenCustomStereo(HW, 'Flip', HW.winPtr);
        
        pause(0.1)
        sampleTime = now-startTime;
        response = sendAndRead(meter, 'M1', '%i,%i,%f', 1.5);
        measured = response(3);
        fprintf('at t=%s: %f\n', datestr(sampleTime, 'SS.FFF'), measured);
        
        secondsPerDay = 60*60*24;
        table(i,:) = [bits(i,:), secondsPerDay*(sampleTime), 1, measured];
    end
    fit = table(:,1:end-1)\table(:,end);
    fprintf('Contributions: [%f,%f,%f] plus %f drift per second\n', ...
        fit(1), fit(2), fit(3), fit(4));
    x = fit(1:3);
    x = x ./ sum(x);
    fprintf('Relative RGB contributions: [%f,%f,%f]', ...
        x(1), x(2), x(3));
catch e
    caughtException = e;
end

if didHWInit
    HW = CleanupHardware(HW); %#ok<NASGU>
end
delete(meter);

if ~isempty(caughtException); rethrow(caughtException); end;

end

