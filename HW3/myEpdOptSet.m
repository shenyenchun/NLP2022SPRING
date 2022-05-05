function epdOpt=myEpdOptSet
% myEpdOptSet: Returns the options (parameters) for EPD

epdOpt.frameSize = 256;
epdOpt.overlap = 0;
epdOpt.volumeRatio = 0.1;

% For method='volhod'
epdOpt.vhRatio=0.11;	% 0.11
epdOpt.diffOrder=2; % 2
epdOpt.volWeight=0.7;
epdOpt.vhMinMaxPercentile=8;		% 5.0%

epdOpt.fixedSegmentCount=[];
epdOpt.extendNum=1;			% Extend front and back
epdOpt.minSegment=0.068;			% Sound segments (in seconds) shorter than or equal to this value are removed
epdOpt.maxSilBetweenSegment=0.416;	% 
epdOpt.minLastWordDuration=0.2;		%