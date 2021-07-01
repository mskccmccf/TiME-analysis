function [ystart,yend,xstart,xend]=findCroppingZero(globalmaximage,fraction)
%find crop of image that removes all infs in wobbly by exhaustive search
xstart=1;
xend=size(globalmaximage,2);
ystart=1;
yend=size(globalmaximage,1);

clean=isempty(find(globalmaximage==0|isinf(globalmaximage), 1));
%cleaninf=isempty(find(isinf(globalmaximage), 1));

while ~clean
    topscore=length(find(globalmaximage(1,:)==0|isinf(globalmaximage(1,:))));
    bottomscore=length(find(globalmaximage(end,:)==0|isinf(globalmaximage(end,:))));
    leftscore=length(find(globalmaximage(:,1)==0|isinf(globalmaximage(:,1))));
    rightscore=length(find(globalmaximage(:,end)==0|isinf(globalmaximage(:,end))));
    imsize=size(globalmaximage);
    worst=max([topscore/imsize(2),bottomscore/imsize(2),leftscore/imsize(1),rightscore/imsize(1)]);
 if worst<fraction||min(imsize)<100
     clean=true;
 else
     if topscore>=max([leftscore,rightscore,bottomscore])
            ystart=ystart+1;
            globalmaximage=globalmaximage(2:end,:);
        else
            if bottomscore>=max([leftscore,rightscore,topscore])
                yend=yend-1;
                globalmaximage=globalmaximage(1:end-1,:);
            else
                if leftscore>=max([bottomscore,rightscore,topscore])
                    xstart=xstart+1;
                    globalmaximage=globalmaximage(:,2:end);
                else
                    xend=xend-1;
                    globalmaximage=globalmaximage(:,1:end-1);
                end
            end
     end
 end
 
    %    clean=length(find(globalmaximage==0|isinf(globalmaximage)))<max(size(globalimage))/4;
       % cleaninf=isempty(find(isinf(globalmaximage), 1));
  %  else
  %      clean=true;
  %  end
end

