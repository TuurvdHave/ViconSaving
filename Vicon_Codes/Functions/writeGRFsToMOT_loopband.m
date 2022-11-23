function writeGRFsToMOT_loopband(forces1,forces2,cop1,cop2,Ty1,Ty2,FrameRate,outputfilename,Frame); %%(GRFTz, tStart, sF, fname, isFZ, tInfo)
% Purpose:  Write ground reaction forces applied at COP to a 
%           motion file (fname) for input into the SimTrack
%           workflow.
%
% Input:   GRFTz is a structure containing the following data
%          tStart is the starting time of the data set
%          sF is the sampling frequency of the data
%          fname is the name of the file to be written.
%
% Output:   The file 'fname' is written to the current directory.
% ASeth, 09-07
% datarate=1000;
% camerarate=100;

Forces1=forces1(:,1:3);
Forces2=forces2(:,1:3);


% Generate column labels for forces, COPs, and vertical torques.
% Order:  GRF(xyz), COP(xyz), T(xyz)
label{1} = 'L_ground_force_vx';
label{2} = 'L_ground_force_vy';
label{3} = 'L_ground_force_vz';
label{4} = 'L_ground_force_px';
label{5} = 'L_ground_force_py';
label{6} = 'L_ground_force_pz';
label{7} = 'R_ground_force_vx';
label{8} = 'R_ground_force_vy';
label{9} = 'R_ground_force_vz';
label{10} = 'R_ground_force_px';
label{11} = 'R_ground_force_py';
label{12} = 'R_ground_force_pz';
label{13} = 'L_ground_torque_x';
label{14} = 'L_ground_torque_y';
label{15} = 'L_ground_torque_z';
label{16} = 'R_ground_torque_x';
label{17} = 'R_ground_torque_y';
label{18} = 'R_ground_torque_z';
%%forceIndex = length(label);


% Initialize 'motion file data matrix' for writing data of interest.
nRowst = length(Forces1);
nCols = length(label)+1;   % plus time
motData = zeros(nRowst, nCols);

% Write time array to data matrix.
time = [Frame(1,1):1/FrameRate:(Frame(1,1) + (nRowst-1)/FrameRate)]'; 
%timeresampled = [tstart:1/2500:(tStart + (nRowst-1)/sF)]';
%timeresampled = [tStart:1/250:(tStart + (nRowst-1)/sF)]';

%nRows = length(timeresampled);
%motData = zeros(nRows, nCols);
%motData(:, 1) = timeresampled;

% Write force data to data matrix.
% NOTE:  each field of mCS.forces has xyz components.
forceData=[Forces2(:,1) Forces2(:,2) Forces2(:,3) cop2(:,1) cop2(:,2) cop2(:,3)  Forces1(:,1) Forces1(:,2) Forces1(:,3) cop1(:,1) cop1(:,2) cop1(:,3) zeros(nRowst,1) Ty2 zeros(nRowst,1)  zeros(nRowst,1) Ty1 zeros(nRowst,1) ];
             
motData=[time forceData];
%% If the coordinate frame does not have FY as vertical
% if isFZ,
%     if isfield(tInfo, 'rotation')
%         rot = tInfo.rotation;
%     else
%         rot = [1 0 0;  0 1 0; 0 0 1];
%     end
%     forceData = rot3DVectors(rot, forceData);
% end

%% om de frequentie in de fp file op een 10-voud te krijgen.

% newforceData=interp1(time,forceData,timeresampled);
% motData(:, 2:end) = newforceData;          


%motData= resample(motData,2500,1000)


%%  Open file for writing.
fid=fopen(outputfilename,'w');
if fid == -1
    error(['unable to open ', outputfilename]);
end

% Write header.
fprintf(fid, 'name %s\n', outputfilename);
fprintf(fid, 'datacolumns %d\n', nCols);
fprintf(fid, 'datarows %d\n', nRowst);
fprintf(fid, 'range %d %d\n', time(1), time(nRowst));
fprintf(fid, 'endheader\n\n');

% Write column labels.
fprintf(fid, '%20s\t', 'time');
for i = 1:nCols-1,
	fprintf(fid, '%20s\t', label{i});
end

% Write data.
for i = 1:nRowst
    fprintf(fid, '\n'); 
	for j = 1:nCols
        fprintf(fid, '%20.8f\t', motData(i, j));
    end
end

fclose(fid);
return;

