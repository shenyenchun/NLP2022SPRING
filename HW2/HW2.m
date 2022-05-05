waveFile='star_noisy.wav';
frameSize=256;
overlap=0;
au=myAudioRead(waveFile); y=au.signal; fs=au.fs; nbits=au.nbits;
y=y*2^nbits/2;
frameMat=enframe(y, frameSize, overlap);
frameNum=size(frameMat, 2);
% disp(frameNum)
% p = polyfit(1:256,frameMat(1:256,1),3)
% disp(p)
p = polyfit(1:250,y(6001:6250),3)
for i=1:250
    %frameMat(:,i)=frameMat(:,i)-round(mean(frameMat(:,i)));
    %disp(frameMat(:,i));
%     p = polyfit(1:250,frameMat(i,:),3)
%     p = polyfit(i,y(6000+i),3)
    z(i) = polyval(p,i)
    az(i)=y(6000+i)-round(z(i));		% Zero justification
end
zcr1=sum(frameMat(1:end-1, :).*frameMat(2:end, :)<0);			% Method 1
zcr2=sum(frameMat(1:end-1, :).*frameMat(2:end, :)<=0);			% Method 2
sampleTime=(1:length(y))/fs;
frameTime=((0:frameNum-1)*(frameSize-overlap)+0.5*frameSize)/fs;

subplot(3,1,1); plot(sampleTime, y); xlabel(waveFile);
% subplot(3,1,2); plot(frameTime, zcr1, '.-', frameTime, zcr2, '.-');
subplot(3,1,2); plot(1:250, y(6001:6250), '.-', 1:250, z(1:250), '.-');
subplot(3,1,3); plot(1:250, az(1:250));
title('ZCR'); xlabel('Time (sec)');
legend('Method 1', 'Method 2');