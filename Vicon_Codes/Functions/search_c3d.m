function [ location ] = search_c3d( variable, name )
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here

for i=1:length(variable);
    if strcmp(variable(i).name, name);
        location=i;
    end
end
if ~exist('location','var')
    location = 0; 
end
end

