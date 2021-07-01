%test stabilization of data
%via nonlinear transform
%location contains pre-rigidly aligned tiffs cropped to remove non-common
%area

%outputs nonrigidly aligned versions and versions with background
%subtracted via a 10 frame moving min
%this is a variant over global moving min since linear factorization methods did not
%seem to work well (an alternative would be to use windowed variant of
%linear factorization, i.e. build up globally from computation on blocsk
%but this sounds excessive

location='D:\core\aditistuff\FullDataSetNew\SIFT Output VERSION 2_Aditi edited\cropped\';
outlocation='D:\core\aditistuff\FullDataSetNew\SIFT Output VERSION 2_Aditi edited\cropped_aligned\';

files=ls([location,'*.tif']);


for fileind=347:347
    %1:size(files,1)
    cleanname=deblank(files(fileind,:));
imagename=[location,cleanname];
image=loadSimpleStackTiff(imagename);
image(image==0)=1;%avoid zeros

%align
transformedimage=image;
im1=image(:,:,1);
im1prewarp=im1;
for i=1:size(image,3)-1
    im2=image(:,:,i+1);
    %this range of scales seems to be a good compromise
    %more fine scale distorts cells and less gobally perfect
    %less seems to have progressive coarse scale slide %was 100 25,1,1
    %try upping middle without fine
%    [warpt1tot2,regt2tomatcht1]=imregdemons(im2,im1,[100,50,10,1],'PyramidLevels',4);
    
%does accounting for intensity fluxuation help flare ups?
%makes semse bit not sure it does help
   % im2 = imhistmatch(uint8(im2),uint8(im1prewarp)); 
    %im2(im2==0)=1;%try to avoid those zeros except at margin...
    
    [warpt1tot2,regt2tomatcht1]=imregdemons(im2,im1,[100,50,10,1],'PyramidLevels',4);

    transformedimage(:,:,i+1)=regt2tomatcht1;
    im1=regt2tomatcht1;
    im1prewarp=im2;
end
globalminimage=min(transformedimage,[],3);
[ystart,yend,xstart,xend]=findCroppingZero(globalminimage,.1);
%remove schumutz around edges from black bakground
outname=[outlocation,cleanname(1:end-4)];
writeSimpleStackTiff([outname,'stabilizedimage.tif'],uint8(transformedimage(ystart:yend,xstart:xend,:)));
end

