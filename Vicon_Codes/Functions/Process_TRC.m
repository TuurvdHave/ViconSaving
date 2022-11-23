function [Mark] = Process_TRC(MLabels,Markers,VideoFrameRate,trcfile,RotationMatrix)


% throw away dummy markers (name starts with *) for sprint
indexMarkers = [];
indexMLabels = [];
for i = 1 : length(MLabels)
    if ~strcmp(MLabels{i}(1), '*')
        indexMLabels = [indexMLabels, i];
        indexMarkers = [indexMarkers, (i-1)*3+1, (i-1)*3+2, i*3];
    end
end

Markers = Markers(:, indexMarkers);
MLabels = MLabels(indexMLabels);

% number of markers
nM = length(MLabels);

    [nvF, nc] = size(Markers);
    vFrms = 0:nvF-1;
    vTime = (1/VideoFrameRate*(vFrms));

% After trimming off the ends see if we have any missing markers
[missInds, missCols] = find(abs(Markers) < 1e-2);
uniqueCols = unique(missCols);
missMarks = ~mod(uniqueCols,3).*uniqueCols/3;
missMarks = missMarks(find(missMarks));
allInds = 1:size(Markers);
garbage = [];

% remove garbage markers
if any(garbage),
    good = setdiff(1:nM, garbage);
    MLabels = MLabels(good);
    goodCols = [];
    for I = 1:length(good),
        goodCols = [goodCols, 3*good(I)-2:3*good(I)];
    end
    Markers = Markers(:,goodCols);
end

%Rotate data.
R     = RotationMatrix.markers(1:3,1:3);  
% rotation lab_frame to opensim
    rot =R;%[1 0 0; 0 0 1; 0 -1 0];%[1 0 0; 0 0 1; 0 1 0];
    Markers = rot3DVectors(rot, Markers);

% change all mm units to meters in one shot
Markers = 0.001 * Markers;

Markers(Markers == 0) = NaN; 


err = writeMarkersToTRC(trcfile, Markers, MLabels, VideoFrameRate, vFrms', vTime', 'm');
Mark.Labels = MLabels; Mark.Data = Markers; 
end 