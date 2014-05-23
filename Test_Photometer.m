function [  ] = Test_Photometer()
%TEST_PHOTOMETER Communication test for the PR-524
%   Creates a connection to the PR-524, and reads its serial number
% By Alexander Yuan, April 2014
    caughtException = [];

    delete(instrfind()); % kludge in case of conflicts?

    meter = PR524();
    try
        [~, sn] = sendAndRead(meter, 'D110', '%i,%i'); % read serial number
        fprintf('Requested serial number: %i\n', sn);
    catch e
        caughtException = e;
    end
    delete(meter);

    if ~isempty(caughtException); rethrow(caughtException); end;
end
