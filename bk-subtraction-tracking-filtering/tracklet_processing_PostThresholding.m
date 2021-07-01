

location='D:\core\aditistuff\correctwindowed30_15_withnorm\bksub_manual\';
location='D:\core\aditistuff\correctwindowed30_15_withnorm_median\sub\';
location='D:\core\aditistuff\correctwindowed30_15_withnorm_median\sub\result_1.6thresh\';
location='D:\core\aditistuff\FullDataSetNew\SIFT Output VERSION 2_Aditi edited\cropped_aligned\sub\';

files=ls([location,'*.xml']);
figure
tracknums=[];
alltrackstats={}
alltrackpos={}
for fileind=1:size(files,1)
 cleanname=deblank(files(fileind,:));
file_path=[location,cleanname];
 [trackpos,trackstats] = parseTrackmate(file_path);
 tracknums(fileind)=size(trackpos,2);
 
 alltrackstats{fileind}=trackstats;
  alltrackpos{fileind}=trackpos;
  %{
 subplot(5,5,fileind);
 hold on
 

 for i=1:length(trackstats)
     if~isempty(trackstats{i})
    scatter3(trackstats{i}.displacement,trackstats{i}.vecdif,trackstats{i}.meanvelocity)
     end
 end
 xlabel('displacement');
 zlabel('mean velocity');
 ylabel('avg angle');
 %}
end

%{
%old code for set thresholds on 2 factors
displacementthresh=5;%5;
anglethresh=60;
threshtracknums=zeros(length(alltrackstats),1);
for i=1:length(alltrackstats)
    for j=1:length(alltrackstats{i})
        if (alltrackstats{i}{j}.displacement>displacementthresh&&...
                alltrackstats{i}{j}.vecdif<anglethresh)
            threshtracknums(i,1)=threshtracknums(i,1)+1;
        end
    end
end
 cerror=sum(abs(correctanswer-threshtracknums));
     
%}

%{
qualityvals=[]
for i=1:length(alltrackstats)
    for j=1:length(alltrackstats{i})
        qualityvals=[qualityvals;alltrackstats{i}{j}.meanintensity];
    end
end
lengths=[]
for i=1:length(trackpos)
    lengths=[lengths;length(trackpos{1,i})];
end
%}

%{
old slow version
%optimize thresholds
bestnums=[];
bestangle=[];
bestdisp=[];
bestintensity=[];
bestlenthresh=[];
besterror=inf;

%inc for intensity
intstart=1;%.01;
intinc=.05%.01;
intmax=8;%.2;


for intensitythresh=intstart:intinc:intmax
for lenthresh=2:5
    for anglethresh=10:90
        for displacementthresh=0:30
            threshtracknums=zeros(length(alltrackstats),1);
            for i=1:length(alltrackstats)
                for j=1:length(alltrackstats{i})
                    if (alltrackstats{i}{j}.displacement>displacementthresh&&...
                            alltrackstats{i}{j}.vecdif<anglethresh &&...
                            alltrackstats{i}{j}.meanintensity>intensitythresh)
                        if(size(alltrackpos{i}{j},1)>=lenthresh*framefactor(i))
                            threshtracknums(i,1)=threshtracknums(i,1)+1;
                        end
                    end
                end
            end
            cerror=sum(abs(correctanswer-threshtracknums));
            %have computed for these settings
            if cerror<besterror
                bestnums=threshtracknums;
                bestangle=anglethresh;
                bestdisp=displacementthresh;
                bestlenthresh=lenthresh;
                bestintensity=intensitythresh;
                besterror=cerror;
            end
        end
    end
end
end
%}
%{
allrawcounts=[]
for i=1:length( alltrackstats)
    allrawcounts(i)=length(alltrackstats{i});
end

%new version


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
intstart=0;
intinc=.0125;
intmax=1.25;
updates=0;

for intensitythresh=intstart:intinc:intmax
    for lenthresh=2:5
        for anglethresh=10:.5:90
            for displacementthresh=0:.5:30
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
resultset(answerset).meanerror=mean(abs(bestnums-correctanswer)./correctanswer);
resultset(answerset).updates=updates;
resultset(answerset).bestnums=bestnums;
resultset(answerset).bestangle=bestangle;
resultset(answerset).bestdisp=bestdisp;
resultset(answerset).bestlenthresh=bestlenthresh;
resultset(answerset).bestintensity=bestintensity;
end
%}