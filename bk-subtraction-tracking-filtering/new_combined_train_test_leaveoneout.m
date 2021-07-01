% script to run tracklet filtering model training on new combined data set
%note this specific script is pretty specific to the bookeeping of labeled
%and unlabled data sets in paper and not really of general use in current
%form

%d1 original 20odd datsets
%d2 new 300 odd
%dx_answers
%dx_framefactor
%load parsed trackmate results for each

%d1meta=load('D:\core\aditistuff\correctwindowed30_15_withnorm_median\loaded_data\subtractedresults_median_1.6_bestresult.mat');
%d2meta=load('D:\core\aditistuff\FullDataSetNew\loaded_full_1.6.mat');
%note this is 

%only subset of 2 have answers so slightly different to select random subset of these 50%
d2_answered=find(d2meta.allanswered);


%concatenate these
malltrackstats={d1meta.alltrackstats{:},d2meta.alltrackstats{d2_answered}};
malltrackpos={d1meta.alltrackpos{:},d2meta.alltrackpos{d2_answered}};
mcorrectanswer=[d1meta.allanswers(:,:);d2meta.allanswers(d2_answered,:)];
mframefactor=[d1meta.framefactor(:);d2meta.framefactor(d2_answered)];


% now make leave one out data set to a data set with original names so can run old scrip
%directly
parfor excludedone=1:length(malltrackstats)
    excludedone
    keepers=ones(1,length(malltrackstats));
    keepers(excludedone)=0;
    keepers=logical(keepers);
    
    alltrackstats={malltrackstats{keepers}};
    alltrackpos={malltrackpos{keepers}};
    correctanswer=mcorrectanswer(keepers,:);
    framefactor=mframefactor(keepers);
    
    %call threshold setting script
    resultset=thresholdDiscoveryf(alltrackstats,alltrackpos,correctanswer,framefactor);
    %alternative_thresholdDiscovery;
    
    mresultset{excludedone}=resultset;
    
    alltrackstats=malltrackstats(~keepers);
    alltrackpos=malltrackpos(~keepers);
    correctanswer=mcorrectanswer(~keepers,:);
    framefactor=mframefactor(~keepers);
    
    
    %run on these
    threshtracknums=tracklet_processing_CountWithThreshf(resultset,alltrackstats,alltrackpos,framefactor);
    
    leftountanswers(excludedone,:)=threshtracknums;
end

figure;
subplot(1,3,1)
scatter(mcorrectanswer(:,1),leftountanswers(:,1));
subplot(1,3,2)
scatter(mcorrectanswer(:,2),leftountanswers(:,2));
subplot(1,3,3)
scatter(mcorrectanswer(:,3),leftountanswers(:,3));

mean(abs(mcorrectanswer-leftountanswers)./mcorrectanswer)

corrcoef(mcorrectanswer(:,1),leftountanswers(:,1))
corrcoef(mcorrectanswer(:,2),leftountanswers(:,2))
corrcoef(mcorrectanswer(:,3),leftountanswers(:,3))

CCC1 = f_CCC([mcorrectanswer(:,1),leftountanswers(:,1)],.05)
CCC2 = f_CCC([mcorrectanswer(:,2),leftountanswers(:,2)],.05)
CCC3 = f_CCC([mcorrectanswer(:,3),leftountanswers(:,3)],.05)


%coallate parameters from each leave one out run
allparameters=[]
    for countset=1:3
         allparameters(countset).bestangle=[];
        allparameters(countset).bestdisp=[];
        allparameters(countset).bestlen=[];
        allparameters(countset).bestintensity=[];
    end
for i=1:length(mresultset)
    for countset=1:3
        cresult=mresultset{i};
        allparameters(countset).bestangle=[allparameters(countset).bestangle;cresult(countset).bestangle];
        allparameters(countset).bestdisp=[allparameters(countset).bestdisp;cresult(countset).bestdisp];
        allparameters(countset).bestlen=[allparameters(countset).bestlen;cresult(countset).bestlenthresh];
        allparameters(countset).bestintensity=[allparameters(countset).bestintensity;cresult(countset).bestintensity];
    end
end

%now visualize parameters used over all the runs
figure
   for countset=1:3
            subplot(1,3,countset);
            hold on
            scatter(ones(size(allparameters(countset).bestangle)),allparameters(countset).bestangle);
            scatter(2*ones(size(allparameters(countset).bestdisp)),allparameters(countset).bestdisp);
            scatter(3*ones(size(allparameters(countset).bestlen)),allparameters(countset).bestlen);
            scatter(4*ones(size(allparameters(countset).bestintensity)),allparameters(countset).bestintensity);
            xticks([1,2,3,4]);
            xticklabels({'angle','displacement','length','intensity'});
   end
   
   resultset=[];
   for answertset=1:3
       resultset(answerset).bestangle=mean(allparameters(answerset).bestangle);
       resultset(answerset).bestdisp=mean(allparameters(answerset).bestdisp);
       resultset(answerset).bestlenthresh=mean(allparameters(answerset).bestlen);
       resultset(answerset).bestintensity=mean(allparameters(answerset).bestintensity);
   end
   
 %finally using the average results  resultset compute answers on both 
   
    
    %run on all the original data using the average parameter values
    threshtracknums_set1=tracklet_processing_CountWithThreshf(resultset,d1meta.alltrackstats,d1meta.alltrackpos,d1meta.framefactor);
    threshtracknums_set2=tracklet_processing_CountWithThreshf(resultset,d2meta.alltrackstats,d2meta.alltrackpos,d2meta.framefactor);
    
return

%{
figure;
subplot(1,3,1)
scatter(correctanswer(:,1),resultset(1).bestnums);
subplot(1,3,2)
scatter(correctanswer(:,2),resultset(2).bestnums);
title('training data results alt')
subplot(1,3,3)
scatter(correctanswer(:,3),resultset(3).bestnums);
%}

%{
'training'
corrcoef(correctanswer(:,1),threshtracknums(:,1))
corrcoef(correctanswer(:,2),threshtracknums(:,2));
corrcoef(correctanswer(:,3),threshtracknums(:,3));
%}
%{
%assemble combined
d2fullpredictions=zeros(length(d2meta.alltrackpos),3);
%d2 part of training data
d2fullpredictions(d2_training,:)=threshtracknums(length(d1_training)+1:end,:);



%now test on unused subset
%concatenate complement of training
alltrackstats={d1meta.alltrackstats{d1_testing},d2meta.alltrackstats{d2_testing}};
alltrackpos={d1meta.alltrackpos{d1_testing},d2meta.alltrackpos{d2_testing}};
correctanswer=[d1meta.allanswers(d1_testing,:);d2meta.allanswers(d2_testing,:)];
framefactor=[d1meta.framefactor(d1_testing);d2meta.framefactor(d2_testing)];
%}

%{
figure;
subplot(1,3,1)
scatter(correctanswer(:,1),threshtracknums(:,1));
subplot(1,3,2)
scatter(correctanswer(:,2),threshtracknums(:,2));
title('test data results alt ')
subplot(1,3,3)
scatter(correctanswer(:,3),threshtracknums(:,3));


'testing'
corrcoef(correctanswer(:,1),threshtracknums(:,1))
corrcoef(correctanswer(:,2),threshtracknums(:,2))
corrcoef(correctanswer(:,3),threshtracknums(:,3))

%d2 part of training data
d2fullpredictions(d2_testing,:)=threshtracknums(length(d1_testing)+1:end,:);


%}
