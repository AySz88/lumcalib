function [  ] = Test_Photometer()
%TEST_PHOTOMETER Communication test for the PR-524
%   Creates a connection to the PR-524, and reads its serial number
% By Alexander Yuan, April 2014
    caughtException = [];

    delete(instrfind()); % kludge in case of conflicts?

    meter = PR524();
    try
        data = sendAndRead(meter, 'D110', '%i,%i'); % read serial number
        sn = data(2);
        fprintf('This PR-524''s serial number is: %i\n', sn);
    catch e
        caughtException = e;
    end
    delete(meter);

    if ~isempty(caughtException); rethrow(caughtException); end;
end
