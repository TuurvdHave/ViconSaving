function [CoPL, CoPR, FzL, FzR, CoP_combined]= calculateCoP_treadmill(A,treshold,fs,outname);

Forces = A;

aY = 180; 
aX = 90; 
aZ = 180;
aY2 = 90; 

roty = [cosd(aY) 0 sind(aY); 0 1 0; -sind(aY) 0 cosd(aY)]; 
roty2 = [cosd(aY2) 0 sind(aY2); 0 1 0; -sind(aY2) 0 cosd(aY2)]; 

rotx = [1 0 0 ; 0 cosd(aX) -sind(aX); 0 sind(aX) cosd(aX)]; 
rotz  = [cosd(aZ) -sind(aZ) 0;sind(aZ) cosd(aZ) 0;0 0 1]; 
rotmat =  [-1 0 0; 0 0 -1; 0 -1 0]*roty;%*rotx;roty*rotx;



%% Filtering the data
% % 2.1. Input data

% 2.2. Filter 
fh = 6;        % [Hz] high-frequency cut-off
nh = 4;         % order of low-pass butterworth filter
fbl = 10;       % [Hz] lower frequency of band-stop
fbh = 30;       % [Hz] lower frequency of band-stop
nb = 4;         % order of band-stop butterworth filter

[Bh,Ah] = butter(nh, fh/(fs/2), 'low');
% [Bb,Ab] = butter(nb, [fbl,fbh]/(fs/2), 'stop');

% 2.3. Filtering the data
% Forces_filt = filtfilt(Bb, Ab, Forces);     %high pass
Forces_filt = filtfilt(Bh, Ah, Forces);    %band pass
 %% Sam - assenstelsel banden gelijk zetten met marker assenstelsel 
% 
% Forces1_filt2 = Forces_filt(:,1:6);
% Forces2_filt2 = Forces_filt(:,7:12);

Forces1_filt(:,1:3) = Forces_filt(:,1:3)*rotmat;
Forces1_filt(:,4:6) = Forces_filt(:,4:6)*rotmat;
Forces2_filt(:,1:3) = Forces_filt(:,7:9)*rotmat;
Forces2_filt(:,4:6) = Forces_filt(:,10:12)*rotmat;

Forces1_filt(:,4:6) = Forces1_filt(:,4:6)./1000; 
Forces2_filt(:,4:6) = Forces2_filt(:,4:6)./1000; 

Forces1_filt = Forces1_filt;
Forces2_filt = Forces2_filt; 


%% Als belasting <<treshold --> krachten en momenten op NaN zetten

Forces1_filt_proper=zeros(length(Forces1_filt),6);
Forces2_filt_proper=zeros(length(Forces2_filt),6);

ind1=Forces1_filt(:,2)>treshold;
ind2=Forces2_filt(:,2)>treshold;

Forces1_filt_proper(ind1,:)=Forces1_filt(ind1,:);
Forces2_filt_proper(ind2,:)=Forces2_filt(ind2,:);

%% berekening cop en Ty assenstelsel loopband
h= 0;
CoPL(:,1) = (Forces1_filt_proper(:,6)+h*Forces1_filt_proper(:,1))./Forces1_filt(:,2);%-2.30;%0.391;
CoPL(:,3) = (-Forces1_filt_proper(:,4)+h*Forces1_filt_proper(:,3))./Forces1_filt(:,2);%+0.391; 
CoPL(:,2)=ones(length(Forces1_filt),1)*h; % in algemeen assenstelsel

CoPR(:,1) = (Forces2_filt_proper(:,6)+h*Forces2_filt_proper(:,1))./Forces2_filt(:,2);%;-2.79;%-0.391;
CoPR(:,3) = (-Forces2_filt_proper(:,4)+h*Forces2_filt_proper(:,3))./Forces2_filt(:,2);%+0.391; 
CoPR(:,2)=ones(length(Forces2_filt),1)*h; % in algemeen assenstelsel

% CoPL(:,1)=(-h*Forces1_filt_proper(:,1)+Forces1_filt_proper(:,6))./Forces1_filt(:,2)-0.391;
% CoPL(:,2)=ones(length(Forces1_filt),1)*h; % in algemeen assenstelsel
% CoPL(:,3)=-(-h*Forces1_filt_proper(:,3)-Forces1_filt_proper(:,4))./Forces1_filt(:,2)+2.54570;
% 
% CoPR(:,1)=(-h*Forces2_filt_proper(:,1)+Forces2_filt_proper(:,6))./Forces2_filt(:,2)-0.391;
% CoPR(:,2)=ones(length(Forces2_filt),1)*h; % in algemeen assenstelsel
% CoPR(:,3)=-(-h*Forces2_filt_proper(:,3)-Forces2_filt_proper(:,4))./Forces2_filt(:,2)+2.54570;
% 
% CoP_combined(:,1)=(-h*Forces1_filt(:,2)-h*Forces2_filt(:,2)+Forces1_filt(:,4)+Forces2_filt(:,4))./(Forces1_filt(:,3)+Forces2_filt(:,3));
% CoP_combined(:,3)=(-h*Forces1_filt(:,1)-h*Forces2_filt(:,1)-Forces1_filt(:,5)-Forces2_filt(:,5))./(Forces1_filt(:,3)+Forces2_filt(:,3));
% FzL=-Forces1_filt(:,1:3);
% FzR=-Forces2_filt(:,1:3);

%%TECHECKEN!
% Tz1=Forces1_filt_proper(:,6)-(CoPL(:,3).*Forces1_filt_proper(:,2))+(CoPL(:,1).*Forces1_filt(:,1)); 
% Ty_alg1 = Tz1;
% 
% Tz2=Forces2_filt_proper(:,6)-(CoPR(:,3).*Forces2_filt_proper(:,2))+(CoPR(:,1).*Forces2_filt(:,1)); 
% Ty_alg2 = Tz2;
% aangepast naar moment omheen y-as (want alle F en M al gentransformeerd
% naar nieuwe assenstelsel (13/01/2017):
Tz1=Forces1_filt_proper(:,5)-(CoPL(:,1).*Forces1_filt_proper(:,3))+(CoPL(:,3).*Forces1_filt(:,1)); 
Ty_alg1 = Tz1;

Tz2=Forces2_filt_proper(:,5)-(CoPR(:,1).*Forces2_filt_proper(:,3))+(CoPR(:,3).*Forces2_filt(:,1)); 
Ty_alg2 = Tz2;

FzL = Forces1_filt_proper;
FzR = Forces2_filt_proper;
CoP_combined = 0;
% [outputfilename,path]= uiputfile('*.xlsx', 'save as');
%NEGATIVE AS INPUT! CORRECT????
writeGRFsToMOT_loopband(Forces1_filt_proper,Forces2_filt_proper,CoPL,CoPR,Ty_alg1,Ty_alg2,fs,outname);