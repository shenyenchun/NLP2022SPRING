% This is the main program for obtaining the recognition rate of EPD

% ====== Add Utility and SAP Toolboxes to the search path
addpath C:\Users\jeff1\Desktop\自然語言處理\Toolbox\utility
addpath C:\Users\jeff1\Desktop\自然語言處理\Toolbox\sap

% ====== Define the directory of the wave files to be tested
 auDir='waveFile';
% auDir='C:\Users\jeff1\Desktop\自然語言處理\HW2\Alphabet and Number';

% ====== Read wave files and the corresponding EPD information
fprintf('Read wave files and EPD info from "%s"...\n', auDir);
auSet=epdAuSetRead(auDir);
fprintf('Collected %d wave files,\n', length(auSet));
if isempty(auSet), error('Cannot read any wave files from the given directory "%s"!\n', auDir); end

% ====== Performance evaluation
epdOpt=myEpdOptSet;
[recogRate, auSet, time]=epdPerfEval(auSet, epdOpt);
fprintf('The overall recognition rate is %.2f%%.\n', recogRate*100);
fprintf('Time = %g sec\n', time);

% ====== Error analysis
epdSpeakerRr(auSet);			% Recognition rate for each speaker
%epdFileCheck(auSet);			% Check bad files
%epdFileCheck(auSet, 'r01942123');	% Check bad files of a given speaker