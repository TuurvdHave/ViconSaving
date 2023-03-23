function [err]= Process_GRF(AnalogSignals,threshold,AnalogFrameRate,VideoFrameRate,outname,Mark,ParameterGroup,RotationMatrix,Footmarker,Frame);

R     =  RotationMatrix.markers(1:3,1:3);
R = R * [-1,0,0;0,-1,0;0,0,1];
R_FP1 =  RotationMatrix.ForcePlate(1:3,1:3);


%get ANKLE MARKERS
AnkleMarkers = {Footmarker.R,Footmarker.L};
for m = 1:length(AnkleMarkers)
   Marker(:,:,m) = Mark.Data(:,find(strcmp(AnkleMarkers{m},Mark.Labels))*3-2:find(strcmp(AnkleMarkers{m},Mark.Labels))*3)*0.001;
end

 
%% remove translation from rotation matrix


% RHeel = Mark.Data(:,find(strcmp(AnkleMarkers{1},Mark.Labels))*3-2:find(strcmp(AnkleMarkers{1},Mark.Labels))*3);
% LHeel =  Mark.Data(:,find(strcmp(AnkleMarkers{2},Mark.Labels))*3-2:find(strcmp(AnkleMarkers{2},Mark.Labels))*3);

VTime = [1/VideoFrameRate:1/VideoFrameRate:size(Mark.Data,1)/VideoFrameRate];
ATime = [1/AnalogFrameRate:1/AnalogFrameRate:size(AnalogSignals,1)/AnalogFrameRate];

f = getForcePlatformFromC3DParameters(ParameterGroup);  % get FP information
nFP = length(f);                                        % get number of FP

% convert corners and origin from mm to m if needed
for I = 1:nFP
    f(I).corners = 0.001*f(I).corners;
    f(I).origin = 0.001*f(I).origin;
end

% Compute COP location & create output matrix
nFR=length(AnalogSignals(:,1));
FP_DatOutL = zeros(nFR,nFP*9);
FP_DatOutR = zeros(nFR,nFP*9);

ForcesR = zeros(nFR,3);
COPR = zeros(nFR,3);
MomentsR = zeros(nFR,3);
ForcesL = zeros(nFR,3);
COPL = zeros(nFR,3);
MomentsL = zeros(nFR,3);
if length(AnkleMarkers) > 2
    ForcesX = zeros(nFR,3);
    COPX = zeros(nFR,3);
    MomentsX = zeros(nFR,3);
end

for i=1:nFP
    % select rotation matrix
    R_FP =  R_FP1;
    
    % get the forces
    Ind = f(i).channel;
    F = AnalogSignals(:,Ind);
    
    Fx= F(:,1);  Fy=F(:,2);  Fz=F(:,3);
    Mx= F(:,4).*0.001;  My=F(:,5).*0.001;  Mz=F(:,6).*0.001;
    
    % get vertical distance between surface and origin FP
    dz = -1 * f(i).origin(3);
    
    % get the COP and free moment around vertical axis
    COPx = (-1*My + dz*Fx)./Fz;
    COPy = (Mx + dz*Fy)./Fz;
    Tz = Mz + COPy.*Fx - COPx.*Fy;
    
    % rotate FP info to correct coordinate system
    Fsel =[Fx Fy Fz];                   % forces
    Tsel =[zeros(length(Tz),2) Tz];     % free moment
    Flab = rot3DVectors(R_FP1,Fsel);    % rotate forces to lab frame
    Tlab = rot3DVectors(R_FP1,Tsel);    % rotate moments to lab frame
    Frot = rot3DVectors(R,Flab);        % rotate forces from lab to Osim
    Trot = rot3DVectors(R,Tlab);        % rotate moments from lab to Osim
    
    % get location COP in world frame
    pFP_lab         = sum(f(i).corners)./4;         % get position vector from lab to origin FP
    pFP_origin      = f(i).origin;                  % FP surface to FP origin
    pFP_origin_rot  = (R_FP1 * pFP_origin');        % rotate this vector to world frame
    COP             = [COPx COPy ones(nFR,1).*-pFP_origin(3)];   % Matrix with COP info
    COP_or_lab      = R_FP * COP';                  % rotate COP to lab
    
    COP_lab = ones(nFR,1)*pFP_lab + ones(nFR,1)*pFP_origin_rot' + COP_or_lab';   % add location FP in lab to COP position
    COProt  = rot3DVectors(R,COP_lab);
    
    %determine which foot hits FP
    pFP_lab     = sum(f(i).corners)./4;
    timeInd = find(abs(Flab(:,2))>25,1);
    if isempty(timeInd)
        timeInd = 1;
    end 
    [~, v_ind]= min(abs(VTime - ATime(timeInd)));
    
    for m = 1:length(AnkleMarkers)
    distance(1,m) = sqrt((COProt(timeInd,1) - Marker(v_ind,1,m)).^2+(COProt(timeInd,2) - Marker(v_ind,3,m)).^2+(COProt(timeInd,3) - Marker(v_ind,2,m)).^2);
    end
%     Rdistance  = sqrt((COProt(timeInd,1) - RHeel(v_ind,1)).^2+(COProt(timeInd,2) - RHeel(v_ind,2)).^2+(COProt(timeInd,3) - RHeel(v_ind,3)).^2);%sqrt((pFP_lab(2) - RHeel(v_ind,2)).^2);
%     Ldistance  = sqrt((COProt(timeInd,1) - LHeel(v_ind,1)).^2+(COProt(timeInd,2) - LHeel(v_ind,2)).^2+(COProt(timeInd,3) - LHeel(v_ind,3)).^2);%sqrt((pFP_lab(2) - LHeel(v_ind,2)).^2);
%     
    % trim COP information with Ftrehsold of 20 N (COP nor reliable if
    % forces are low)
    ind=find(Frot(:,2)<threshold);
    for j=1:3
        COProt(ind,j)   = 0;
        Frot(ind,j)     = 0;
        Trot(ind,j)     = 0;
    end
    
    [min_val,min_ind] = min(distance);
    if min_ind == 1%Rdistance < Ldistance
        ForcesR = ForcesR + Frot;
        MomentsR  = MomentsR + Trot;
        COPR = COPR + COProt;
    elseif min_ind == 2
        ForcesL = ForcesL + Frot;
        MomentsL  = MomentsL + Trot;
        COPL = COPL + COProt;
    elseif min_ind == 3
        ForcesX = ForcesX + Frot;
        MomentsX  = MomentsX + Trot;
        COPX = COPX + COProt;
    end
end

if length(AnkleMarkers)>2
   writeGRFsToMOT_more(ForcesR,ForcesL,ForcesX,COPR,COPL,COPX,MomentsR(:,2),MomentsL(:,2),MomentsX(:,2),AnalogFrameRate,outname);
else
writeGRFsToMOT(ForcesR,ForcesL,COPR,COPL,MomentsR(:,2),MomentsL(:,2),AnalogFrameRate,outname,Frame);
end

err = 1;