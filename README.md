# ViconSaving
These codes export automatically your vicon data to OpenSim data. Ground reaction forces are even allocated to the correct foot automatically. 

How to install the pipeline? 
1)	Extract the folder pipelines.zip to C:\Users\Public\Documents\Vicon\Nexus2.x\Configurations\Pipelines
2)	Open Vicon and you should be able to see the pipeline SaveTrial in the pipeline tab
 
How to use the pipeline? 
1)	Label your data as usual and instead of pushing the blue disk on the right top, you will be able to save your data using this pipeline. 
2)	In the first two steps of the pipeline (‘Filter Analog Data’ and ‘Filter Trajectories’), the force plate data and the marker trajectories will be filtered using a standard filter of 15Hz. 
3)	This pipeline assumes that you make use of events (‘Foot strike’ and ‘Toe off’). This is to either crop the trial or to be able to analyze different motions within one measurement. You don’t have to do put in events, if not uncheck Export ASCII and the whole trial will be analyzed in further steps
4)	Next step in the pipeline will be exporting the C3D-file. No input is needed for this
5)	Exporting the .trc -file should be adapted according to the OpenSim version you are using. 
		When using Opensim 3.x, put TRC Version on ‘Version 3’.
		When using Opensim 4.x, put TRC Version on ‘Version 4’.
6)  Vicon exports the .trc file and leaves gaps (empty cells) within the data when there is no value for that marker during that frame. OpenSim is not able to handle this.
	This Matlab code will fill those gaps with NaNs 
7)	Next, the .mot will be created and needs some input. You need to adapt the input arguments based on which force plates you used and how many are used. 
		When the treadmill is used the first input argument should be ‘1’. Otherwise, it should be ‘0’.
		When running on the treadmill on the subject only ran on one force plate, the second input argument should be ‘1’. Otherwise, it should be ‘0’.
		When walking on the stairs, the third input argument should be ‘1’. Otherwise it should be ‘0’.
		All input arguments should be split by a comma as seen in the figure. 
		If you don't use the heel markers "RHEE" and "LHEE", change the heel marker names in the createmot matlabcode in line 26-27 to your heel marker names. 
8)	The last step in the pipeline is to write a file containing the different events and doesn’t require any inputs. When all settings are correctly defined, you can push play and your trial will be saved correctly and ready to use in OpenSim. 


