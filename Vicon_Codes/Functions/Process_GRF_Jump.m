function [err]= Process_GRF_Jump(AnalogSignals,treshold,AnalogFrameRate,VideoFrameRate,outname,Mark,Markers,ParameterGroup);

R     = rotx(-pi/2)*rotz(pi/2); R=R';    % rotation lab_frame to opensim *roty(-pi/2)
R_FP1 = roty(pi);      R_FP1=R_FP1';   % rotation force plate frame to Lab Frame

%% remove translation from rotation matrix
R=R(1:3,1:3);R=R';
R_FP1=R_FP1(1:3,1:3);R_FP1 =  R_FP1';



f = getForcePlatformFromC3DParameters(ParameterGroup);  % get FP information
nFP = length(f);                                        % get number of FP

% convert corners and origin from mm to m if needed
for I = 1:nFP
    f(I).corners = 0.001*f(I).corners;
    f(I).origin = 0.001*f(I).origin;
end

% Compute COP location & create output matrix
nFR=length(AnalogSignals(:,1));
FP_DatOut = zeros(nFR,nFP*9);

for i=1:nFP
    % select rotation matrix
    R_FP =  R_FP1;
    
    % get the forces
    Ind = f(i).channel;
    F = AnalogSignals(:,Ind);
    
    
    % example of low pass filter
    [a,b]=butter(4,15/(AnalogFrameRate*0.5),'low');%40 Hz, low pass filter.
    F=filtfilt(a,b,F);
    
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
    
    % trim COP information with Ftrehsold of 20 N (COP nor reliable if
    % forces are low)
    ind=find(Frot(:,2)<treshold);
    ind_keep = ind;
    for j=1:3
        COProt(ind,j)   = 0;
        Frot(ind,j)     = 0;
        Trot(ind,j)     = 0;
    end
    
    % store all the information
    FP_DatOut(:,i*6-5:i*6-3)=Frot;              % 1-3 = Force
    FP_DatOut(:,i*6-2:i*6)=COProt;             % 4-6 = COP
    FP_DatOut(:,nFP*6+i*3-2:nFP*6+i*3)=Trot;    % Store Free moments after all the Force and COP information
    

    
    
end


RHeel = Mark.Data(:,find(strcmp('MAL_LAT_R',Mark.Labels))*3-2:find(strcmp('MAL_LAT_R',Mark.Labels))*3);
LHeel =  Mark.Data(:,find(strcmp('MAL_LAT_L',Mark.Labels))*3-2:find(strcmp('MAL_LAT_L',Mark.Labels))*3);

VTime = [1/VideoFrameRate:1/VideoFrameRate:size(Mark.Data,1)/VideoFrameRate];
ATime = [1/AnalogFrameRate:1/AnalogFrameRate:size(FP_DatOut,1)/AnalogFrameRate];

% ind1=Temp(:,2)>treshold;
% YForce = Temp(:,2);
% f1 = figure('Position',[ 1921 247 1536 757],'name',outname);subplot(3,1,1), plot(YForce,'k'),hold on
% cut_off = 50;

Forces1_filt_proper = [FP_DatOut(:,1:6),FP_DatOut(:,13:15)];
Forces2_filt_proper = [FP_DatOut(:,7:12),FP_DatOut(:,16:18)];

% above = YForce>=cut_off;
% 
% n = 1;
% n2 = 1;
% 
% for i = 1:size(YForce,1)-1;
%     if above(i)==0
%         if above(i+1) == 1
%             IC(n) = i+1;
%             n = n+1;
%         end
%         
%     elseif above(i) == 1
%         if above(i+1) == 0
%             TO(n2) = i+1;
%             n2 =n2+1;
%         end
%     end
% end

% figure(f1)
% subplot(311)
% lims = get(gca,'YLim');
% for i = 1:size(IC,2);
%     figure(f1);
%     ic = plot([IC(i) IC(i)],[0 lims(2)]) ;
%     set(ic,'LineWidth',1.5,'LineStyle','--','Color',[0.26 0.47 0.89]);
% end
% 
% for i = 1:size(TO,2);
%     figure(f1);
%     to = plot([TO(i) TO(i)],[0 lims(2)]);
%     set(to,'LineWidth',1.5,'LineStyle',':','Color',[0.24 0.87 0.02]);
% end
% if IC(1) > TO(1)
%     TO =  TO(2:end);
% end
% if IC(end)> TO(end)
%     IC = IC(1:end-1);
% end
% 
% cl = 1; cr=1;
% for i = 1:size(IC,2)
%     [~, v_ind ]= min(abs(VTime - ATime(IC(i))));
%     Lpos = LHeel(v_ind,1);
%     Rpos = RHeel(v_ind,1);
%     
%     if Lpos > Rpos%left stride %orig >
%         Forces1_filt_proper(IC(i):TO(i),:)=0;
%         ICL(cl) = IC(i);
%         TOL(cl) = TO(i);
%         cl = cl+1;
%     else %right stride
%         Forces2_filt_proper(IC(i):TO(i),:)=0;
%         ICR(1,cr) = IC(i);
%         TOR(1,cr)= TO(i);
%         cr = cr+1;
%     end
%     
%     if i == 1
%         if Lpos > Rpos%left stride
%             Forces1_filt_proper(1:TO(i),:)=0;
%             Forces2_filt_proper(1:IC(i),:)=0;
%             
%         else
%             Forces2_filt_proper(1:TO(i),:)=0;
%             Forces1_filt_proper(1:IC(i),:)=0;
%         end
%     end
%     
%     if i == size(IC,2)
%         if Lpos > Rpos%left stride
%             Forces1_filt_proper(IC(i):end,:)=0;
%             Forces2_filt_proper(TO(i):end,:)=0;
%         else
%             Forces2_filt_proper(IC(i):end,:)=0;
%             Forces1_filt_proper(TO(i):end,:)=0;
%         end
%         
%     end
% end
% Events(1,:) = ATime(ICR);
% Events(2,:) = ATime(TOR);
% EventsL(1,:) = ATime(ICL);
% EventsL(2,:) = ATime(TOL);

% text = {'IC R' ;'TO R';'IC L';'TO L'};
%write down events in excel file
% eventsname = [outname(1:end-4) '_events.xlsx'];
% 
% xlswrite(eventsname,Events,'sheet1','B1');
% xlswrite(eventsname,EventsL,'sheet1','B3');
% xlswrite(eventsname,text,'sheet1','A1');


% figure(f1),
% subplot(312)
% plot(ATime,Forces1_filt_proper(:,2),'k')
% hold on
% plot(ATime,Forces2_filt_proper(:,2),'b')
% subplot(313)
% plot(VTime,RHeel(:,2),'k')
% hold on
% plot(VTime,LHeel(:,2),'b')
% legend('Right','Left')
% pause(0.1)

writeGRFsToMOT_loopband(Forces1_filt_proper(:,1:3),Forces2_filt_proper(:,1:3),Forces1_filt_proper(:,4:6),Forces2_filt_proper(:,4:6),Forces1_filt_proper(:,8),Forces2_filt_proper(:,8),AnalogFrameRate,outname);

err = 1;