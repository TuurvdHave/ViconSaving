function CreateMot(ITreadmill,IPlates,Stairs)
addpath('C:\Users\Public\Documents\Vicon\Nexus2.x\Configurations\Pipelines\Vicon_Codes\Functions')
%% Define Input
%--------------

vicon = ViconNexus();
[path, name] = vicon.GetTrialName();
main_root   = path; %directory to the place where the C3D files you want to process are stored
path_out    = path; %directory where you want to store the OSIM-files
if strcmp(ITreadmill,'1')
Treadmill   = 1; %Used treadmill configuration in the lab (1=Yes, 0=No)
else 
Treadmill   = 0; %Used overground configuration in the lab (1=Yes, 0=No)
end 

if strcmp(ITreadmill,'1') && strcmp(IPlates,'1')
Treadmill_OnePlate = 1; %running on one plate (1=Yes, 0=No)
else 
Treadmill_OnePlate = 0; %running/walking on two separate plates (1=Yes, 0=No)
Treadmill_TwoPlate = 1;
end 

%Provide names of 2 markers on the foot to automatically couple side to
%grf. IMPORTANT: does not work when you are standing with both feet on the
%force plate (at any point in the movement).
Footmarker.R = 'RHEE';
Footmarker.L = 'LHEE';

treshold    = 20; % treshold to define valid FP contact.
FP_filter   = 15; % treshold for the low-pass filter for the force plate data.
%% Proces Files
%--------------

if Treadmill
    RotationMatrix.markers    =  [0, -1, 0;0, 0, 1;-1, 0, 0]; %rotation matrix Vicon World-CS to Opensim World-CS, angle should be in degrees! Lab dependent!!!
    RotationMatrix.ForcePlate =  [-1, 0, 0;0, 1, 0;0, 0, -1]; %rotation matrix Force plate CS to Vicon World-CS, angle should be in degrees! Lab dependent!!!
else
    RotationMatrix.markers     =  [0, -1, 0;0, 0, 1;-1, 0, 0]; %rotation matrix Vicon World-CS to Opensim World-CS, angle should be in degrees! Lab dependent!!!
    RotationMatrix.ForcePlate  =  [0, 1, 0;1, 0, 0;0, 0, -1]; %rotation matrix Force plate CS to Vicon World-CS, angle should be in degrees! Lab dependent!!!
end
    
    %input
    %-----
    Path_In = fullfile(path,[name '.c3d']); %C3D directory
    
    %output
    %------
    Path_GRF    = fullfile(path_out, [name '.mot']); %output grf directory
    
    if ~exist(fullfile(path_out))
        mkdir(fullfile(path_out));
    end
    
    %% Load data
    %-----------
    [Markers,MLabels,VideoFrameRate,AnalogSignals,ALabels, AUnits, AnalogFrameRate,Event,ParameterGroup,CameraInfo]...
        = readC3D(Path_In);
    Mark.Labels = MLabels; Mark.Data = Markers;
    Frame = [ParameterGroup(1).Parameter(1).data(1,1)/VideoFrameRate ParameterGroup(1).Parameter(2).data(1,1)/VideoFrameRate];
    %% update the trc file 
        [TRCdata,labels] = importTRCdata(fullfile(path,[name '.trc']));
        
        writeMarkersToTRC(fullfile(path,[name '.trc']),TRCdata(:,3:end),labels(3:end),VideoFrameRate,[Frame(1,1)*VideoFrameRate:round(Frame(1,2)*VideoFrameRate)]',[Frame(1,1):1/VideoFrameRate:(Frame(1,1) + (size(TRCdata,1)-1)/VideoFrameRate)]','mm')

   
        %% PROCESS GRF for OpenSimProcessing
        %-----------------------------------
        if Treadmill
            if Treadmill_OnePlate
                [~]= Process_GRF_TM(AnalogSignals,treshold,AnalogFrameRate,VideoFrameRate,Path_GRF,Mark,Markers,ParameterGroup,RotationMatrix,Footmarker,Frame);
            elseif Treadmill_TwoPlate
                [~]= Process_GRF_TM2(AnalogSignals,treshold,AnalogFrameRate,VideoFrameRate,Path_GRF,Mark,Markers,ParameterGroup,RotationMatrix,Footmarker,Frame);
            end
        else
            if strcmpi(Stairs,'1')
            [err]= Process_GRF_stairs(AnalogSignals,treshold,AnalogFrameRate,VideoFrameRate,Path_GRF,Mark,ParameterGroup,RotationMatrix,Footmarker,Frame);   
            else 
            [err]= Process_GRF(AnalogSignals,treshold,AnalogFrameRate,VideoFrameRate,Path_GRF,Mark,ParameterGroup,RotationMatrix,Footmarker,Frame);
            end
        end
end 
