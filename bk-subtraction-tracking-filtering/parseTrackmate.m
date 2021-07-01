function [trackpos,trackstats,trackcolor,trackquality] = parseTrackmate(directory)
%note depends on trackmate reader that ships in fiji
G = trackmateGraph(directory);
if (~isempty(G))
    x = G.Nodes.POSITION_X;
    y = G.Nodes.POSITION_Y;
    z = G.Nodes.POSITION_Z;
    
    D=indegree(G);
    tracks={};
    c=1;
    for i=1:length(D)
        if(D(i)==0)
            v=bfsearch(G,i);
            if(length(v)>1)
                tracks{c}=v;
                c=c+1;
            end
        end
    end
    
    trackpos={};
    trackcolor={};
    trackquality={};
    for i=1:length(tracks)
        trackpos{i}=G.Nodes{tracks{i},{'POSITION_X','POSITION_Y'}};
        if(~max(strcmp('MEAN_INTENSITY01',G.Nodes.Properties.VariableNames))==0)
            trackcolor{i}=G.Nodes{tracks{i},{'MEAN_INTENSITY01','MEAN_INTENSITY02','MEAN_INTENSITY03','MEAN_INTENSITY04'}};
        else
            if(~max(strcmp('QUALITY',G.Nodes.Properties.VariableNames))==0)
                trackquality{i}=G.Nodes{tracks{i},'QUALITY'};
            end
        end
    end
    
    trackstats=[];
    for i=1:length(trackpos)
        
        currpos=trackpos{i};
        trackstats{i}.displacement=(sum((currpos(1,:)-currpos(end,:)).^2).^.5);
        displacements=currpos(1:end-1,:)-currpos(2:end,:);
        angles=[];
        for j=1:size(displacements,1)-1
            a=displacements(j,:);
            a=a./(sum(a.^2)).^.5;
            b=displacements(j+1,:);
            b=b./(sum(b.^2)).^.5;
            angles(j)=acosd(dot(a,b));
        end
        trackstats{i}.vecdif=sum(angles)/length(angles);
        %not used and not defined if just 1 long
        % trackstats{i}.cor=corrcoef(displacements);
        % trackstats{i}.cor=trackstats{i}.cor(1,2);
        trackstats{i}.velocites=(sum((displacements.^2)').^.5);
        trackstats{i}.meanvelocity=mean( trackstats{i}.velocites);
        %compute mean intensity for track
        if~isempty(trackquality)
            trackstats{i}.meanintensity=mean(trackquality{i});
        end
        trackstats{i}.starttime=G.Nodes(tracks{i}(1),'FRAME');
    end

else
    trackpos=[];
    trackstats=[];
    trackcolor=[];
    trackquality=[];
end
end
