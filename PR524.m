classdef PR524 < serial
    %PR524 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function meter = PR524()
            port = FindPortOf('PR Instrument');
            meter@serial(port);
            
            % Communication Settings:
            % For some reason, the meter wants to be sent just one
            % character at a time, so don't let MATLAB send CR/LF to the
            % device.  Reading is fine though, since MATLAB will buffer the
            % CR/LF.  The device doesn't seem to use any sort of standard
            % flow control.
            set(meter, 'Terminator', {'CR/LF', ''});
            set(meter, 'FlowControl', 'none');
            
            fopen(meter);
            send(meter, 'PHOTO'); % Set the meter to Remote Mode
            
            send(meter, 'C'); % Clear any errors
            pause(0.1);
            if get(meter, 'BytesAvailable') > 0
                % error was cleared
                % ignore any "Instrument error cleared" message
                fscanf(meter);
            end
        end
        
        function delete(meter)
            if meter.isvalid && strcmpi(get(meter, 'status'), 'open')
                send(meter, 'Q'); % Turn off Remote Mode
                fclose(meter);
            end
            delete@serial(meter)
        end
        
        function send(meter, cmd)
            % Must send one character at a time :(

            % Make sure the command ends with CR/LF
            if length(cmd) < 2 || ~strcmpi(cmd(end-1:end), sprintf('\r\n'))
                cmd = sprintf('%s\r\n', strtrim(cmd));
            end

            for idx = 1:length(cmd)
                fprintf(meter, cmd(idx));
            end
        end

        function varargout = sendAndRead(meter, cmd, format, pauseTime)
            % Output is same as Instrument Control Toolbox's fscanf
            if nargin < 3 || isempty(format)
                format = '%s'; % discards the CR/LF terminator
            end
            if nargin < 4 || isempty(pauseTime)
                pauseTime = 0.1;
                % TODO maybe: if strcmpi(cmd(1), 'M'); pauseTime = 4.0; end;
                % or a "wait for data" flag that does the fscanf without checking for data?
            end

            varargout = cell(1, min(nargout, 1));

            meter.send(cmd);
            pause(pauseTime);
            
            if get(meter, 'BytesAvailable') > 0
                [varargout{:}] = fscanf(meter, format);
            else
                if nargout >= 1; varargout{1} = ''; end;
                if nargout >= 2; varargout{2} = 0; end;
                if nargout >= 3; varargout{3} = 'No response.'; end;
                % TODO throw warning iff narargout < 3?
            end
        end
    end
end

