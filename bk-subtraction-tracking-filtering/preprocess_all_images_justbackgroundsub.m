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

location='D:\core\aditistuff\FullDataSetFixTest\cropped_aligned\';
location='D:\core\aditistuff\FullDataSetNew\SIFT Output VERSION 2_Aditi edited\cropped_aligned\';
outlocation=location;

files=ls([location,'*.tif']);

%this is now in pasted variable specifying window size (to account for
%variable frame rate in different movies)
%windows=[30 30 60 60 30 30 60 30 30 30 60 60 60 60 60 60 30 60 30 30 30 30 30];

%crashed on 347
for fileind=347:size(files,1)
    cleanname=deblank(files(fileind,:));
    imagename=[location,cleanname];
    image=loadSimpleStackTiff(imagename);
    
    %subtract background in windowed form
    bksubtractedimage=image;
    bksubtractedimagesubtraction=image;
    windowbk=windows(fileind);%30;
    
    for i=1:size(bksubtractedimage,3)
        startwindow=max(1,i-windowbk/2);
        endwindow=min(size(bksubtractedimage,3),i+windowbk/2);
        %background=min(transformedimage(:,:,startwindow:endwindow),[],3);
        %alternate median background
        windowsize=endwindow-startwindow;
        
        subvolume=image(:,:,startwindow:endwindow);
        background=zeros(size(subvolume,1),size(subvolume,2),1);
        for j=1:size(background,1)
            for k=1:size(background,2)
                background(j,k)=median(subvolume(j,k,:));
            end
        end
        
        bksubtractedimage(:,:,i)=image(:,:,i)./(background);
        bksubtractedimagesubtraction(:,:,i)=image(:,:,i)-(background);
    end
    
    outnamediv=[outlocation,'div\',cleanname(1:end-4)];
    outnamesub=[outlocation,'sub\',cleanname(1:end-4)];
    
    imsize=size(bksubtractedimage);
    cropped=reshape(bksubtractedimage, [imsize(1),imsize(2),1,1,imsize(3)]);
    bfsave(single(cropped),[outnamediv,'stabilizedimage_bksubmin_div.tif']);
    
    %save subtraction instead of division version
    croppedsubtracted=reshape(bksubtractedimagesubtraction, [imsize(1),imsize(2),1,1,imsize(3)]);
    bfsave(single(croppedsubtracted),[outnamesub,'stabilizedimage_bksubmin_subtraction.tif']);
end

