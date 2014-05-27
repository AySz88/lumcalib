function [ HW ] = CleanupHardware( HW )
%CLEANUPHARDWARE Cleans up screens and re-enables keyboard in MATLAB
%   If you call InitializeHardware, it is your responsibility to call this
%   this function before you exit, even there were errors!

    assert(nargin >= 1, 'CleanupHardware:NoParameter', ...
        'Need a hardware parameter struct, but none passed in!');
    
    assert(nargout >= 1, 'CleanupHardware:HWNotSaved', ...
        ['Hardware parameter from CleanupHardware is not being' ...
        ' saved, but it almost certainly should replace the old HW!']);
    
    %TODO not guaranteed that the HW passed out from here will actually be
    %   properly saved and passed back up, and in such a case this warning
    %   won't be triggered!
    %   Use ref's/pointers (make HW a class deriving from handle) to fix?
    assert(isfield(HW, 'initialized') && HW.initialized, ...
        'CleanupHardware:NoInitializedHW', ...
        ['An initialized HW struct was not passed in! The real error'...
        ' is probably that some other function called me when it'...
        ' shouldn''t have done so.  *** Please ONLY have a function' ...
        ' call CleanupHardware if the SAME function initialized' ...
        ' it earlier (and gets didHWInit == true). *** Other functions' ...
        ' might still need the hardware to be ready!']);
    
    Screen('CloseAll');
    ListenChar(0);
    
%     PsychPortAudio('Close');
    
    HW.initialized = false;
end

