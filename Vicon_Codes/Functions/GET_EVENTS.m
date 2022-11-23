%%% Read and write gait - events out of C3D-file. 

function out = GET_EVENTS(ParameterGroup,VideoFrameRate,outname);


%get start frame
Headers = search_c3d( ParameterGroup, 'TRIAL' );
start = search_c3d(ParameterGroup(Headers).Parameter,'ACTUAL_START_FIELD');
startframe = ParameterGroup(Headers).Parameter(start).data(1);

[ RHeelstrike,LHeelstrike,RToeoff,LToeoff ,No_events] = read_events_Nexus( ParameterGroup,startframe,VideoFrameRate );

if ~No_events
ExcelHeader = {'RHeelstrike','LHeelstrike','RToeoff','LToeoff'}; 

xlswrite(outname,ExcelHeader);
xlswrite(outname,RHeelstrike','Sheet1','A2');
xlswrite(outname,LHeelstrike','Sheet1','B2');
xlswrite(outname,RToeoff','Sheet1','C2');
xlswrite(outname,LToeoff','Sheet1','D2');

end
out = 1;
end 
