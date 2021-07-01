
function threshtracknums=tracklet_processing_CountWithThreshf(resultset,alltrackstats,alltrackpos,framefactor)
    
%assume already loaded data
%go over all tracks 3 times creating tally of numbers with each of 3
%optimal parameters


threshtracknums=zeros(length(alltrackstats),3);
for k=1:3
    displacementthresh=resultset(k).bestdisp;
    anglethresh=resultset(k).bestangle;
    lenthresh=resultset(k).bestlenthresh;
    intensitythresh=resultset(k).bestintensity;
    
    for i=1:length(alltrackstats)
        for j=1:length(alltrackstats{i})
            testresult=alltrackstats{i}{j}.displacement>displacementthresh&...
                alltrackstats{i}{j}.vecdif<anglethresh &...
                alltrackstats{i}{j}.meanintensity>intensitythresh &...
                size(alltrackpos{i}{j},1)>=lenthresh*framefactor(i);
            if(testresult)
                threshtracknums(i,k)=threshtracknums(i,k)+1;
            end
        end
    end
    
end
