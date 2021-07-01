

%just parses all trackmate results into a shared data structure saved in a
%mat file and used later on
location='D:\core\aditistuff\correctwindowed30_15_withnorm\bksub_manual\';
location='D:\core\aditistuff\FullDataSetFixTest\cropped_aligned\sub\'%
%location='D:\core\aditistuff\correctwindowed30_15_withnorm_median\sub\result_2.25thresh\'
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

end
