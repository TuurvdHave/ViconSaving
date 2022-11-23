function [ RHeelstrike,LHeelstrike,RToeoff,LToeoff ,No_events] = read_events_Nexus( ParameterGroup,startframe,VideoFrameRate )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

[d,aantal]=size(ParameterGroup);
event=search_c3d(ParameterGroup,'EVENT');

number_of_gait_events=search_c3d(ParameterGroup(event).Parameter,'USED');
if ParameterGroup(event).Parameter(number_of_gait_events).data
    No_events = 0;
    side_event=search_c3d(ParameterGroup(event).Parameter, 'CONTEXTS');
    type_of_event=search_c3d(ParameterGroup(event).Parameter, 'LABELS');
    frame_of_event=search_c3d(ParameterGroup(event).Parameter, 'TIMES');
    
    m=1;
    x=1;
    o=1;
    p=1;
    z=1;
    
    % Determine left and right events
    for n=1:ParameterGroup(event).Parameter(number_of_gait_events).data;
        a=strcmp(ParameterGroup(event).Parameter(side_event).data(n),'Right');
        b=strcmp(ParameterGroup(event).Parameter(type_of_event).data(n),'Foot Strike');
        c=strcmp(ParameterGroup(event).Parameter(side_event).data(n),'Left');
        d=strcmp(ParameterGroup(event).Parameter(type_of_event).data(n),'Foot Off');
        if (a==1) && (b==1);
            RHeelstrike(z)=ParameterGroup(event).Parameter(frame_of_event).data(2,n);
            z=z+1;
        end;
        
        if (a==1) && (d==1);
            RToeoff(x)=ParameterGroup(event).Parameter(frame_of_event).data(2,n);
            x=x+1;
        end;
        if (c==1) && (b==1);
            LHeelstrike(o)=ParameterGroup(event).Parameter(frame_of_event).data(2,n);
            o=o+1;
        end;
        if (c==1) && (d==1);
            LToeoff(p)=ParameterGroup(event).Parameter(frame_of_event).data(2,n);
            p=p+1;
        end;
    end;
    if exist('RHeelstrike');
        RHeelstrike = sort(RHeelstrike);
        RHeelstrike=RHeelstrike-(startframe/VideoFrameRate);
    else
        RHeelstrike=NaN;
    end
    
    if exist('LHeelstrike');
        LHeelstrike = sort(LHeelstrike);
        LHeelstrike=LHeelstrike-(startframe/VideoFrameRate);
        
    else
        LHeelstrike=NaN;
    end
    
    
    
    if exist('RToeoff')
        RToeoff=sort(RToeoff);
        RToeoff=RToeoff-(startframe/VideoFrameRate);
    else RToeoff=NaN;
    end
    
    if exist('LToeoff');
        LToeoff=sort(LToeoff);
        LToeoff=LToeoff-(startframe/VideoFrameRate);
    else LToeoff=NaN;
    end
    
    
else
    LToeoff=NaN; RToeoff=NaN;    LHeelstrike=NaN; RHeelstrike=NaN;
    No_events = 1;
end




end

