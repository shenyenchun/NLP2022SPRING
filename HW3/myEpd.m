function [epInSampleIndex, epInFrameIndex] = myEpd(au, epdOpt, showPlot)
% myEpd: a simple example of EPD
%
%	Usage:
%		[epInSampleIndex, epInFrameIndex] = endPointDetect(au, showPlot, epdOpt)
%			epInSampleIndex: two-element end-points in sample index
%			epInFrameIndex: two-element end-points in frame index
%			au: input wave object
%			epdOpt: parameters for EPD
%			showPlot: 0 for silence operation, 1 for plotting
%
%	Example:
%		waveFile='SingaporeIsAFinePlace.wav';
%		au=waveFile2obj(waveFile);
%		epdOpt=myEpdOptSet;
%		showPlot = 1;
%		out = myEpd(au, epdOpt, showPlot);

%	Roger Jang, 20040413, 20070320, 20130329

% if nargin<1, selfdemo; return; end
% if nargin<2, epdOpt=myEpdOptSet; end
% if nargin<3, showPlot=0; end
% 
% wave=au.signal; fs=au.fs;
% frameSize=epdOpt.frameSize; overlap=epdOpt.overlap;
% wave=double(wave);				% convert to double data type (轉成資料型態是 double 的變數)
% wave=wave-mean(wave);				% zero-mean substraction (零點校正)
% frameMat=enframe(wave, frameSize, overlap);	% frame blocking (切出音框)
% frameNum=size(frameMat, 2);			% no. of frames (音框的個數)
% volume=frame2volume(frameMat);			% compute volume (計算音量)
% volumeTh=max(volume)*epdOpt.volumeRatio;	% compute volume threshold (計算音量門檻值)
% index=find(volume>=volumeTh);			% find frames with volume larger than the threshold (找出超過音量門檻值的音框)
% epInFrameIndex=[index(1), index(end)];
% epInSampleIndex=frame2sampleIndex(epInFrameIndex, frameSize, overlap);	% conversion from frame index to sample index (由 frame index 轉成 sample index)
% 
% if showPlot,
% 	subplot(2,1,1);
% 	time=(1:length(wave))/fs;
% 	plot(time, wave); axis tight;
% 	line(time(epInSampleIndex(1))*[1 1], [min(wave), max(wave)], 'color', 'g');
% 	line(time(epInSampleIndex(end))*[1 1], [min(wave), max(wave)], 'color', 'm');
% 	ylabel('Amplitude'); title('Waveform');
% 
% 	subplot(2,1,2);
% 	frameTime=((1:frameNum)-1)*(frameSize-overlap)+frameSize/2;
% 	plot(frameTime, volume, '.-'); axis tight;
% 	line([min(frameTime), max(frameTime)], volumeTh*[1 1], 'color', 'r');
% 	line(frameTime(index(1))*[1 1], [0, max(volume)], 'color', 'g');
% 	line(frameTime(index(end))*[1 1], [0, max(volume)], 'color', 'm');
% 	ylabel('Sum of abs.'); title('Volume');
% 	
% 	U.wave=wave; U.fs=fs;
% 	if ~isempty(epInSampleIndex)
% 		U.voicedY=U.wave(epInSampleIndex(1):epInSampleIndex(end));
% 	else
% 		U.voicedY=[];
% 	end
% 	set(gcf, 'userData', U);
% 	uicontrol('string', 'Play all', 'callback', 'U=get(gcf, ''userData''); sound(U.wave, U.fs);', 'position', [20, 20, 100, 20]);
% 	uicontrol('string', 'Play detected', 'callback', 'U=get(gcf, ''userData''); sound(U.voicedY, U.fs);', 'position', [150, 20, 100, 20]);
% end
% 
% % ====== Self demo
% function selfdemo
% mObj=mFileParse(which(mfilename));
% strEval(mObj.example);

if nargin<1, selfdemo; return; end
if ischar(au), au=myAudioRead(au); end	% au is actually the wave file name
if nargin<2 || isempty(epdOpt), epdOpt=epdOptSet(au.fs); end
if nargin<3, showPlot=0; end

y=au.signal; fs=au.fs; nbits=au.nbits;
if size(y, 2)~=1, error('Wave is not mono!'); end

frameSize=epdOpt.frameSize;
overlap=epdOpt.overlap;
frameRate=fs/(frameSize-overlap);
minSegment=round(epdOpt.minSegment*frameRate);		% In terms of no. of frames
maxSilBetweenSegment=round(epdOpt.maxSilBetweenSegment*frameRate);		% In terms of no. of frames
%minLastWordDuration=round(epdOpt.minLastWordDuration*frameRate);

% ====== Compute volume/hod
y=double(y);					% convert to double data type
frameMat=buffer2(y, frameSize, overlap);	% frame blocking
frameMat=frameZeroMean(frameMat, 2);		% zero justification
frameNum=size(frameMat, 2);					% no. of frames
volume=frame2volume(frameMat);				% compute volume
hod=frame2ashod(frameMat, epdOpt.diffOrder);	% compute HOD
% ====== Compute vh and its thresholds
volume=volume/max(volume); hod=hod/max(hod);	% Normalization before mixing
vh=volume*epdOpt.volWeight+(1-epdOpt.volWeight)*hod;

epdOpt.fs=fs;	% Used in epdBySingleCurve
epdOpt.minMaxPercentile=epdOpt.vhMinMaxPercentile;	% Used in epdBySingleCurve
epdOpt.ratio=epdOpt.vhRatio;	% Used in epdBySingleCurve
[epInSampleIndex, epInFrameIndex, soundSegment, zeroOneVec, vhMin, vhMax, vhTh, bestTh]=epdBySingleCurve(vh, epdOpt, 1);
%keyboard

% ====== Plotting
if showPlot
	subplot(3,1,1);
	time=(1:length(y))/fs;
	frameTime=frame2sampleIndex(1:frameNum, frameSize, overlap)/fs;
	plot(time, y);
	for i=1:length(soundSegment)
		line(frameTime(soundSegment(i).beginFrame)*[1 1], 2^nbits/2*[-1, 1], 'color', 'g');
		line(frameTime(soundSegment(i).endFrame)*[1 1], 2^nbits/2*[-1, 1], 'color', 'm');
	end
	axisLimit=[min(time) max(time) -2^nbits/2, 2^nbits/2];
	if -1<=min(y) && max(y)<=1
		axisLimit=[min(time) max(time) -1, 1];
	end
	axis(axisLimit);
	ylabel('Amplitude');
	title('Waveform');
	
	subplot(3,1,2);
	plot(frameTime, volume, '.-', frameTime, hod, '.-');
	legend('Volume', 'HOD');
	axis tight;
	ylabel('Volume & HOD');
	title('Volume & HOD');

	subplot(3,1,3);
	plot(frameTime, vh, '.-');
	axis tight;
	axisLimit=axis;
	line([min(frameTime), max(frameTime)], vhMin*[1 1], 'color', 'c'); text(max(frameTime), vhMin, 'min');
	line([min(frameTime), max(frameTime)], vhMax*[1 1], 'color', 'k'); text(max(frameTime), vhMax, 'max');
	line([min(frameTime), max(frameTime)], vhTh*[1 1], 'color', 'r'); text(max(frameTime), vhTh, '\theta')
	line([min(frameTime), max(frameTime)], bestTh*[1 1], 'color', 'r', 'linewidth', 2); text(max(frameTime), bestTh, 'best \theta');
	fprintf('vhMin=%g, vhMax=%g, vhTh=%g, bestTh=%g\n', vhMin, vhMax, vhTh, bestTh);
	for i=1:length(soundSegment)
		line(frameTime(soundSegment(i).beginFrame)*[1 1], [0, max(vh)], 'color', 'g');
		line(frameTime(soundSegment(i).endFrame)*[1 1], [0, max(vh)], 'color', 'm');
		text(frameTime(round((soundSegment(i).beginFrame+soundSegment(i).endFrame)/2)), axisLimit(4), int2str(i), 'horizontal', 'center', 'vertical', 'top');
	end
	ylabel('VH');
	title('VH');
	
	U.y=y; U.fs=fs;
	if max(U.y)>1, U.y=U.y/(2^nbits/2); end
	if ~isempty(epInSampleIndex)
		U.voicedY=U.y(epInSampleIndex(1):epInSampleIndex(end));
	else
		U.voicedY=[];
	end
	set(gcf, 'userData', U);
	uicontrol('string', 'Play all', 'callback', 'U=get(gcf, ''userData''); sound(U.y, U.fs);');
	uicontrol('string', 'Play detected', 'callback', 'U=get(gcf, ''userData''); sound(U.voicedY, U.fs);', 'position', [100, 20, 100, 20]);
end

% ====== Self demo
function selfdemo
mObj=mFileParse(which(mfilename));
strEval(mObj.example);