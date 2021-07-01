
%new version
function resultset=thresholdDiscoveryf(alltrackstats,alltrackpos,correctanswer,framefactor)

%coallate these into vectors to improve efficency
adisplacementvalues={};
avecdiff={};
ameanintensity={};
alengths={};
for i=1:length( alltrackstats)
displacementvalues=zeros(length(alltrackstats{i}),1);
vecdiff=zeros(length(alltrackstats{i}),1);
meanintensity=zeros(length(alltrackstats{i}),1);
lengths=zeros(length(alltrackstats{i}),1);
    for j=1:length(alltrackstats{i})
        displacementvalues(j)=alltrackstats{i}{j}.displacement;
        vecdiff(j)=alltrackstats{i}{j}.vecdif;
        meanintensity(j)= alltrackstats{i}{j}.meanintensity;
        lengths(j)=size(alltrackpos{i}{j},1);
    end
adisplacementvalues{i}=displacementvalues;
avecdiff{i}=vecdiff;
ameanintensity{i}=meanintensity;
alengths{i}=lengths;
end

resultset=[];
for answerset=1:size(correctanswer,2)


bestnums=[];
bestangle=[];
bestdisp=[];
bestintensity=[];
bestlenthresh=[];
besterror=inf;
besterrorcount=inf;
%inc for intensity
%subtraction
%intstart=1;%.01;
%intinc=.05%.01;
%intmax=6;%.2;

%div
intstart=0; %was 0
intinc=.0125;
intmax=6;%1.25; was maxed out? in all old results
updates=0;
lengthsperset=[3,4,5];
for intensitythresh=intstart:intinc:intmax
   for lenthresh=lengthsperset(answerset):lengthsperset(answerset)
  %        for lenthresh=2:5
        for anglethresh=5:.25:90
            for displacementthresh=0:.5:60
                threshtracknums=zeros(length(alltrackstats),1);
                for i=1:length(alltrackstats)
                    
                    testresult=adisplacementvalues{i}>displacementthresh&...
                        avecdiff{i}<anglethresh &...
                        ameanintensity{i}>intensitythresh &...
                        alengths{i}>=lenthresh*framefactor(i);
                    
                    threshtracknums(i,1)=length(find(testresult));
                    
                end
                cerror=sum(abs(correctanswer(:,answerset)-threshtracknums));
                fractionerror=mean(abs(threshtracknums-correctanswer(:,answerset))./correctanswer(:,answerset));
                %have computed for these settings
                %if fractionerror<=besterror
                if cerror<=besterror
                    updates=updates+1;
                    bestnums=threshtracknums;
                    bestangle=anglethresh;
                    bestdisp=displacementthresh;
                    bestlenthresh=lenthresh;
                    bestintensity=intensitythresh;
                    besterror=cerror;%fractionerror;
                    besterrorcount=cerror;
                end
            end
        end
    end
end

resultset(answerset).besterror=besterror;
resultset(answerset).besterrorcount=besterrorcount;
resultset(answerset).meanerror=(abs(bestnums-correctanswer(:,answerset))./correctanswer(:,answerset));
resultset(answerset).updates=updates;
resultset(answerset).bestnums=bestnums;
resultset(answerset).bestangle=bestangle;
resultset(answerset).bestdisp=bestdisp;
resultset(answerset).bestlenthresh=bestlenthresh;
resultset(answerset).bestintensity=bestintensity;
end