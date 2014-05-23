function [  ] = Test_Photometer( port )
%TEST_PHOTOMETER Communication test for the PR-524
%   Creates a connection to the PR-524, and reads its serial number
% By Alexander Yuan, April 2014
    caughtException = [];
    
    if nargin < 1 || isempty(port)
        port = FindPortOf('PR Instrument');
    end

    delete(instrfind()); % kludge in case of conflicts?

    meter = open(port);
    try
        sn = sendAndRead(meter, 'D110'); % read serial number
        fprintf('%s\n', sn);
    catch e
        caughtException = e;
    end
    close(meter);

    if ~isempty(caughtException); rethrow(caughtException); end;
end

function meter = open(port)
    meter = serial(port);
    
    % Communication Settings:
    % For some reason, the meter wants to be sent just one character at a
    % time, so don't let MATLAB send CR/LF to the device.  Reading is fine
    % though, since MATLAB will buffer the CR/LF.  The device doesn't seem
    % to use any sort of standard flow control.
    meter.Terminator = {'CR/LF', ''};
    meter.FlowControl = 'none';
    
    fopen(meter);
    send(meter, 'PHOTO'); % Set the meter to Remote Mode
    
    send(meter, 'C'); % Clear any errors
    pause(0.1);
    if meter.BytesAvailable > 0
        % cleared an error; ignore any "Instrument error cleared" message
        fscanf(meter);
    end
end

function close(meter)
    if meter.isvalid && strcmpi(meter.status, 'open')
        send(meter, 'Q'); % Turn off Remote Mode
        fclose(meter);
    end
    delete(meter);
end

function send(meter, cmd)
    % Must send one character at a time :(
    
    % Make sure the command ends with CR/LF
    if length(cmd) < 2 || ~strcmpi(cmd(end-1:end), sprintf('\r\n'))
        cmd = sprintf('%s\r\n', strtrim(cmd));
    end
    
    fprintf('Sending %s...\n', strtrim(cmd));
    
    for idx = 1:length(cmd)
        fprintf(meter, cmd(idx));
    end
end

function varargout = sendAndRead(meter, cmd, format, pauseTime)
    if nargin < 3
        format = '%s'; % discards the CR/LF terminator
    end
    if nargin < 4
        pauseTime = 0.1;
        % TODO maybe: if strcmpi(cmd(1), 'M'); pauseTime = 2.0; end;
        % or a "wait for data" flag that does the fscanf without checking for data?
    end
    
    varargout = cell(1, nargout);
    
    send(meter, cmd);
    pause(pauseTime);
    
    fprintf('About to read %i bytes...', meter.BytesAvailable);
    if meter.BytesAvailable > 0
        [varargout{:}] = fscanf(meter, format);
    else
        if nargout >= 1; varargout{1} = ''; end;
        if nargout >= 2; varargout{2} = 0; end;
        if nargout >= 3; varargout{3} = 'No response.'; end;
        % TODO throw warning iff narargout < 3?
    end
end
