%test stabilization of data
%via nonlinear transform
%location contains pre-rigidly aligned tiffs cropped to remove non-common
%area



location='D:\core\aditistuff\FullDataSetNew\SIFT Output VERSION 2_Aditi edited\';
outlocation=[location,'cropped\'];
%location='D:\core\aditistuff\FullDataSet\Output_SIFT aligned FIJI\';
%outlocation='D:\core\aditistuff\FullDataSet\Output_SIFT_Cropped\';

files=ls([location,'*.tif']);


for fileind=1:size(files,1)
    cleanname=deblank(files(fileind,:));
    imagename=[location,cleanname];
    image=loadSimpleStackTiff(imagename);
    globalminimage=min(image,[],3);
    [ystart,yend,xstart,xend]=findCroppingZero(globalminimage,.25);
    %remove schumutz around edges from black bakground
    cropped=image(ystart:yend,xstart:xend,:);
    imsize=size(cropped);
    if min(imsize(1:2))<600
        ['weird case ',imagename]
    end
    outname=[outlocation,cleanname(1:end-4)];
    
    writeSimpleStackTiff([outname,'_crop.tif'],uint8(image(ystart:yend,xstart:xend,:)));
end

