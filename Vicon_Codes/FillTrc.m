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
RotationMatrix.markers     =  [0, -1, 0;0, 0, 1;-1, 0, 0];


% --- Extract marker coordinate data (skip frame/time) ---
coordData = Mark.Data;  % [N_frames x N_coords]

% --- Determine sizes ---
numFrames = size(coordData, 1);
numCoords = size(coordData, 2);
numMarkers = numCoords / 3;

% --- Reshape to separate X, Y, Z per marker ---
coordReshaped = reshape(coordData, [numFrames, 3, numMarkers]);  % [frames x 3 x markers]

% --- Apply rotation to each marker ---
R = RotationMatrix.markers;

for i = 1:numMarkers
    coords = squeeze(coordReshaped(:, :, i));  % [N x 3]
    
    % Handle rows with NaNs by skipping them
    nanRows = any(isnan(coords), 2);
    validRows = ~nanRows;
    
    rotated = coords;  % Initialize
    rotated(validRows, :) = (R * coords(validRows, :)')';  % Rotate only valid rows
    
    coordReshaped(:, :, i) = rotated;
end

% --- Reshape back to flat matrix format ---
rotatedData = reshape(coordReshaped, [numFrames, numCoords]);

Frame = [ParameterGroup(1).Parameter(1).data(1,1)/VideoFrameRate ParameterGroup(1).Parameter(2).data(1,1)/VideoFrameRate];
%% update the trc file
[TRCdata,labels] = importTRCdata(fullfile(path,[name '.trc']));

writeMarkersToTRC(fullfile(path,[name '.trc']),rotatedData,labels(3:end),VideoFrameRate,TRCdata(:,1),TRCdata(:,2),'mm')

end