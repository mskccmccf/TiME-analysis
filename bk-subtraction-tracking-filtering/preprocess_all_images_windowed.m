%test stabilization of data
%via nonlinear transform
%this script performs all steps while the set of preprocess_...just...
%perform only one step at a time saving result to disk inbetween

%location contains pre-rigidly aligned tiffs cropped to remove non-common
%area

%outputs nonrigidly aligned versions and versions with background
%subtracted via a 10 frame moving min
%this is a variant over global moving min since linear factorization methods did not
%seem to work well (an alternative would be to use windowed variant of
%linear factorization, i.e. build up globally from computation on blocsk
%but this sounds excessive

location='D:\core\aditistuff\alltestdataprealigned\';
outlocation='D:\core\aditistuff\correctwindowed30_15_withnorm_median\';
location='D:\core\aditistuff\FullDataSet\Output_SIFT aligned FIJI\';
outlocation='D:\core\aditistuff\FullDataSet\alignedresult\';

files=ls([location,'*.tif']);

%this is now 
%windows=[30 30 60 60 30 30 60 30 30 30 60 60 60 60 60 60 30 60 30 30 30 30 30];


for fileind=1:size(files,1)
    cleanname=deblank(files(fileind,:));
imagename=[location,cleanname];
image=loadSimpleStackTiff(imagename);
image(image==0)=1;%avoid zeros
%median prefilter
%not sure why this filter is introducing zeros to something without zeros
%for i=1:size(image,3)
%image(:,:,i)=medfilt2(image(:,:,i),[3,3]);
%end

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
    im2 = imhistmatch(uint8(im2),uint8(im1prewarp));
    
    im2(im2==0)=1;%try to avoid those zeros except at margin...
    
    [warpt1tot2,regt2tomatcht1]=imregdemons(im2,im1,[100,50,10,1],'PyramidLevels',4);

    transformedimage(:,:,i+1)=regt2tomatcht1;
    im1=regt2tomatcht1;
    im1prewarp=im2;
end
%median filter
%extra 3x3x3 med filt after stabilization
%should we really do this.
%transformedimage=medfilt3(transformedimage);

%subtract background in windowed form
bksubtractedimage=transformedimage;
bksubtractedimagesubtraction=transformedimage;
windowbk=windows(fileind);%30;

for i=1:size(bksubtractedimage,3)
 startwindow=max(1,i-windowbk/2);
 endwindow=min(size(bksubtractedimage,3),i+windowbk/2);
 %background=min(transformedimage(:,:,startwindow:endwindow),[],3);
 %alternate median background
 windowsize=endwindow-startwindow;

 subvolume=transformedimage(:,:,startwindow:endwindow);
 background=zeros(size(subvolume,1),size(subvolume,2),1);
 for j=1:size(background,1)
     for k=1:size(background,2)
        background(j,k)=median(subvolume(j,k,:));
     end
 end
 %background=medfilt3(subvolume,[1,1,size(subvolume,3)-1]);
 %background=background(:,:,round(windowsize/2));
 
 bksubtractedimage(:,:,i)=transformedimage(:,:,i)./(background);
 bksubtractedimagesubtraction(:,:,i)=transformedimage(:,:,i)-(background);
end
globalmaximage=max(bksubtractedimage,[],3);
%globalminimage=min(bksubtractedimage,[],3);
%ind=find (isinf(globalmaximage));
%[ypos,xpos]=ind2sub(size(globalmaximage),ind);
%xdist=xpos-(size(globalmaximage,2)/2);
%ydist=ypos-(size(globalmaximage,1)/2);
[ystart,yend,xstart,xend]=findCropping(globalmaximage);
%remove schumutz around edges from black bakground
cropped=bksubtractedimage(ystart:yend,xstart:xend,:);

croppedsubtracted=bksubtractedimagesubtraction(ystart:yend,xstart:xend,:);
%cropped=bksubtractedimage(30:end-30,30:end-30,:);

imsize=size(cropped);
if min(imsize(1:2))<600
    'weird case'
end

outname=[outlocation,cleanname(1:end-4)];

outnamediv=[outlocation,'div\',cleanname(1:end-4)];

outnamesub=[outlocation,'sub\',cleanname(1:end-4)];

cropped=reshape(cropped, [imsize(1),imsize(2),1,1,imsize(3)]);
bfsave(single(cropped),[outnamediv,'stabilizedimage_bksubmin_div.tif']);

%save subtraction instead of division version
croppedsubtracted=reshape(croppedsubtracted, [imsize(1),imsize(2),1,1,imsize(3)]);
bfsave(single(croppedsubtracted),[outnamesub,'stabilizedimage_bksubmin_subtraction.tif']);


writeSimpleStackTiff([outname,'stabilizedimage.tif'],uint8(transformedimage(ystart:yend,xstart:xend,:)));

%saveastiff(single(bksubtractedimage),[outname,'stabilizedimage_bksubmin.tif']);
end

