function FillTrc()
addpath('C:\Users\Public\Documents\Vicon\Nexus2.x\Configurations\Pipelines\Vicon_Codes\Functions')
%% Define Input
%--------------

vicon = ViconNexus();
[path, name] = vicon.GetTrialName();
main_root   = path; %directory to the place where the C3D files you want to process are stored
path_out    = path; %directory where you want to store the OSIM-files

%input
%-----
Path_In = fullfile(path,[name '.c3d']); %C3D directory
%% Load data
%-----------
[Markers,MLabels,VideoFrameRate,AnalogSignals,ALabels, AUnits, AnalogFrameRate,Event,ParameterGroup,CameraInfo]...
    = readC3D(Path_In);
Mark.Labels = MLabels; Mark.Data = Markers;
Frame = [ParameterGroup(1).Parameter(1).data(1,1)/VideoFrameRate ParameterGroup(1).Parameter(2).data(1,1)/VideoFrameRate];
%% update the trc file
[TRCdata,labels] = importTRCdata(fullfile(path,[name '.trc']));

writeMarkersToTRC(fullfile(path,[name '.trc']),TRCdata(:,3:end),labels(3:end),VideoFrameRate,TRCdata(:,1),TRCdata(:,2),'mm')

end