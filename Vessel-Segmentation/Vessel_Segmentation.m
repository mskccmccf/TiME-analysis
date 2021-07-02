%MATLAB SCRIPT THAT READS THE TIFF MOVIE OF REGISTER FRAMES AND EXTRACTS THE
%VESSEL REGIONS.

clear

%location of the tiff movies
tiffDirec = './Alignednew';
%list of files to be processed.
dirList = dir(fullfile(tiffDirec,'*.tif'));

%Process the files one  by one
for j = 1:length(dirList)
    ProcessDir = dirList(j).name;
    % If the data is not loaded, then run this portion of the script when you are in the folder of the images
    flist = imfinfo(fullfile(tiffDirec, ProcessDir));
    img = uint8(zeros([flist(1).Height,flist(1).Width,length(flist)]));
    for i = 1:length(flist)
        img(:,:,i) = imread(fullfile(tiffDirec, ProcessDir), i);
    end
    img = im2double(img);
    
    %% Asuming that registered frames are loaded to Matlab. => img
    %% Filter out the speckle noise in the frames
    
    % %%MEDIAN FILTERING BASED SOLUTION
    % for i = 1:76
    %     MedImg(:,:,i) = medfilt2(img(:,:,i),[5,5]);
    % end
    % %%Assumption: Areas with high temporal variation are vessel regions.
    % Calculate temporal mean
    % MImg = mean(MedImg,3);
    % Calculate temporal standard deviation
    % SImg = sqrt(sum((MedImg-repmat(MImg,1,1,size(MedImg,3))).^2,3)/size(MedImg,3));
    
    
    %% Find the border regions that are empty at some stage due to registration
    L = min(img,[],3)==0;
    J = imclearborder(L);
    L = L-J;
    
    %FIR FILTERING BASED SOLUTION
    fsize = 5;
    for i = 1:size(img,3)
        img(:,:,i) = adapthisteq(img(:,:,i),'numTiles',[4,4]);
    end
    %FImg = (convn(img,ones(fsize,fsize,fsize)/fsize^3,'same'));
    FImg = imgaussfilt3(img,0.5);
    SImg = zeros(size(img(:,:,1)));
    for i = floor(fsize/2)+2:size(img,3)-(floor(fsize/2)+2)
        SImg = abs(FImg(:,:,i+1)-2*FImg(:,:,i)+FImg(:,:,i-1))+medfilt2(SImg);
        %imshow(SImg.*(~L));pause(0.1)
    end
    SImg = SImg.*(~L);
    SImg = SImg./max(SImg(:));
    
    %Smooth up the segmantation via morphological filtering
    BinarySImg =SImg>max(otsuthresh(imhist(SImg)),0.4);
    BinarySImg =  imerode(BinarySImg,strel('disk',3));
    BinarySImg =  imdilate(BinarySImg,strel('disk',5));
    BinarySImg = imfill(BinarySImg,'holes');
    
    %Get rid of small and very large  areas of segmentation. 
    ConnComp = bwconncomp(BinarySImg);
    AreaComp = regionprops(ConnComp,'Area');
    canvas = zeros(size(BinarySImg));
    Area = [];
    Thickness = [];
    
    counter = 1;
    for i = 1:ConnComp.NumObjects
        if AreaComp(i).Area/10^6>10^-3 && AreaComp(i).Area/10^6<0.1
            canvas(ConnComp.PixelIdxList{i}) = counter;
            Thickness(counter) = max(max(bwdist(~(canvas==counter))));
            Area(counter) = (AreaComp(i).Area/(numel(SImg)))*100;
            SkelSImg = bwmorph(canvas==counter,'thin',Inf);
            counter = counter+1;
        else
            BinarySImg(ConnComp.PixelIdxList{i}) = 0;
        end
    end
    
    % Display and record the results
    close all
    imshow(BinarySImg)
    newDir=erase(ProcessDir, '.tif');
    imwrite( BinarySImg, sprintf('Res_%s.png', newDir))
    clear img Fimg Area Thickness canvas ConnComp AreaComp SImg
end