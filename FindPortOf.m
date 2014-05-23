function [ port ] = FindPortOf( deviceToFind )
%FINDPORTOF Finds the COM port of the named device via the Windows registry
%   Detailed explanation goes here

NONE = 0;
MIDDLE = 1;
START = 2;
CASE_INSENSITIVE = 3;
EXACT = 4;

bestMatchSoFar = NONE;
port = [];

% Query registry for USB devices
usbEnumKey = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\';
queryFlags = '/s /f FriendlyName /t REG_SZ';
[~, usbEnum] = dos(['REG QUERY ' usbEnumKey ' ' queryFlags]);

% Extract the relevant parts of the 'reg query' output
patternForCOM = '^    FriendlyName    REG_SZ    (.*?COM.*?)$';
%patternForCOM = '^    FriendlyName    REG_SZ    (.*?)$';
deviceStrings = regexp(usbEnum, patternForCOM, 'tokens', 'dotexceptnewline', 'lineanchors');

% Parse the device names and port numbers
devices = regexp([deviceStrings{:}], '(.*) \((COM[\d*])\)', 'tokens');
for devIdx = 1:length(devices)
    device = devices{devIdx}{1};
    if ~isempty(device) % if empty, regex didn't match at all
        name = device{1};
        if bestMatchSoFar < EXACT && strcmp(name, deviceToFind)
            port = device{2};
            bestMatchSoFar = EXACT;
        elseif bestMatchSoFar < CASE_INSENSITIVE && strcmpi(name, deviceToFind)
            port = device{2};
            bestMatchSoFar = CASE_INSENSITIVE;
        elseif bestMatchSoFar < START && strncmpi(name, deviceToFind, min(length(name), length(deviceToFind)))
            port = device{2};
            bestMatchSoFar = START;
        elseif bestMatchSoFar < MIDDLE && ~isempty(strfind(name, deviceToFind))
            port = device{2};
            bestMatchSoFar = MIDDLE;
        end
    end
end
end

