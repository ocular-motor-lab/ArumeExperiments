%%
%% Drawing illusory tilt stimuli based on cafe wall illusion
%%
%% - This script draws a tunnel with illusory tilted walls based on the cafe wall illusion
%% - the stimulus is drawing using patches in a matlab axis from -1 to +1.
%%
%%
% -- begin set parameters

h = [0 0]; % horizon point
L = 10; % length of the corridor
N1 = 16; % number of tiles per row
N2 = 20; % number of rows

bw = [0 0 0 ; 1 1 1]; % colors of the tiles

shift = 1.0;

hl = 0.02; % grey line thickness
colorl = 0.6*[1 1 1]; % grey line color

CENTER_SQUARE = 0; % 1 for center blurry square 0 for circle

% -- end set parameters

% height of the figure should be enough to fit the pattern diagonally

figure('color','k','visible','off');
axis equal
set(gca,'xlim',[-1 1]*1.1,'ylim',[-1 1]*1.1,'visible','off')
set(gca,'innerposition',[0 0 1 1]);
set(gcf,'position',[20 20 1000 1000])

for side = 1:4
    for j=1:N2
        for i=0:N1+1
            
            w = 2/N1; % width of the tiles
            h = L/N2; % height of the tiles
            
            color = bw(mod(i+1,2)+1,:); % color of the current tile
            
            rowshift = mod(shift*2/N1*(j-1),2); % shift of the current row. 
            
            
            cornerx = -1 + 2/N1*(i-1) + rowshift; % position of the current tile
            cornery = L/N2*(j-1);
            
            % cycle the tiles if the shift move them outside
            if ( cornerx > 1 )
                cornerx = cornerx -2*(N1+2)/N1;
            end
            
            if ( cornerx+w*2 < -1 )
                cornerx = cornerx +2*(N1+2)/N1;
            end
            
            % if the tile is just outside don't draw it.
            if ( (cornerx+w <= -1 ) || (cornerx >= 1) )
                   continue;
            end
            
            % corners of the tile without perspective
            corners = [
                cornerx         cornery;
                cornerx + w     cornery;
                cornerx + w     cornery + h;
                cornerx         cornery + h;
                cornerx         cornery];
            
            corners(1,1) = max(corners(1,1), -1);
            corners(2,1) = min(corners(2,1), 1);
            corners(3,1) = min(corners(3,1), 1);
            corners(4,1) = max(corners(4,1), -1);
            corners(5,1) = max(corners(5,1), -1);
            
            % corners of the tile with perspective distorsion
            switch(side)
                case 1
                    corners(:,1) = corners(:,1) ./ (1+corners(:,2));
                    corners(:,2) = -1 ./(1+ corners(:,2));
                case 2
                    corners = [-1 ./(1+ corners(:,2))  -corners(:,1) ./ (1+corners(:,2))];
                case 3
                    corners(:,1) = - corners(:,1) ./ (1+corners(:,2));
                    corners(:,2) =  1 ./(1+ corners(:,2));
                case 4
                    corners = [1 ./(1+ corners(:,2))  corners(:,1) ./ (1+corners(:,2))];
            end
            
            % draw the tile
            patch(corners(:,1), corners(:,2),zeros(size(corners(:,2))), 'facecolor',color,'edgecolor','none');
        end
        
        % Draw the grey squares
        
        if ( j==1)
            continue; % do not do a square for the first row of tiles
        end
        
        corners = [
            -1          L/N2*(j-1);
            1           L/N2*(j-1);
            1           L/N2*(j-1) + hl;
            -1          L/N2*(j-1) + hl;
            -1          L/N2*(j-1)];
        
        corners(1,1) = max(corners(1,1), -1);
        corners(2,1) = min(corners(2,1), 1);
        corners(3,1) = min(corners(3,1), 1);
        corners(4,1) = max(corners(4,1), -1);
        corners(5,1) = max(corners(5,1), -1);
        
        
        switch(side)
            case 1
                corners(:,1) = corners(:,1) ./ (1+corners(:,2));
                corners(:,2) = -1 ./(1+ corners(:,2));
            case 2
                corners = [-1 ./(1+ corners(:,2))  -corners(:,1) ./ (1+corners(:,2))];
            case 3
                corners(:,1) = - corners(:,1) ./ (1+corners(:,2));
                corners(:,2) =  1 ./(1+ corners(:,2));
            case 4
                corners = [1 ./(1+ corners(:,2))  corners(:,1) ./ (1+corners(:,2))];
        end
        
        patch(corners(:,1), corners(:,2),zeros(size(corners(:,2))), 'facecolor',colorl,'edgecolor','none');
        
        
        
        % draw diagonal lines
        
        corners = [
            -1          0;
            -1           L;
            -1+hl           L;
            -1+hl          0;
            -1          0];
        
        corners(1,1) = max(corners(1,1), -1);
        corners(2,1) = min(corners(2,1), 1);
        corners(3,1) = min(corners(3,1), 1);
        corners(4,1) = max(corners(4,1), -1);
        corners(5,1) = max(corners(5,1), -1);
        
        
        switch(side)
            case 1
                corners(:,1) = corners(:,1) ./ (1+corners(:,2));
                corners(:,2) = -1 ./(1+ corners(:,2));
            case 2
                corners = [-1 ./(1+ corners(:,2))  -corners(:,1) ./ (1+corners(:,2))];
            case 3
                corners(:,1) = - corners(:,1) ./ (1+corners(:,2));
                corners(:,2) =  1 ./(1+ corners(:,2));
            case 4
                corners = [1 ./(1+ corners(:,2))  corners(:,1) ./ (1+corners(:,2))];
        end
        
        patch(corners(:,1), corners(:,2),zeros(size(corners(:,2))), 'facecolor',colorl,'edgecolor','none');
        
        % draw diagonal lines
        
        corners = [
            1          0;
            1           L;
            1-hl           L;
            1-hl          0;
            1          0];
        
        corners(1,1) = max(corners(1,1), -1);
        corners(2,1) = min(corners(2,1), 1);
        corners(3,1) = min(corners(3,1), 1);
        corners(4,1) = max(corners(4,1), -1);
        corners(5,1) = max(corners(5,1), -1);
        
        
        switch(side)
            case 1
                corners(:,1) = corners(:,1) ./ (1+corners(:,2));
                corners(:,2) = -1 ./(1+ corners(:,2));
            case 2
                corners = [-1 ./(1+ corners(:,2))  -corners(:,1) ./ (1+corners(:,2))];
            case 3
                corners(:,1) = - corners(:,1) ./ (1+corners(:,2));
                corners(:,2) =  1 ./(1+ corners(:,2));
            case 4
                corners = [1 ./(1+ corners(:,2))  corners(:,1) ./ (1+corners(:,2))];
        end
        
        patch(corners(:,1), corners(:,2),zeros(size(corners(:,2))), 'facecolor',colorl,'edgecolor','none');
    end
end

%%
    tempfile = 'temp.png';
    source_fig = gcf;
    set(gcf,'PaperUnits','inches','PaperPosition',[0 0 10 10])
    set(source_fig,'InvertHardcopy','off');
    print(source_fig,['-r',num2str(216)], '-dpng', tempfile);
illusionimage = imread(tempfile);
  %%  
    %%
[xmesh, ymesh] = meshgrid(-2160/2:2160/2-1, -2160/2:2160/2-1);

R1 = 200;
R2 = 2160/2/1.1-350;
S1 = 20;
S2 = 20;

rs = sqrt(max(xmesh.^2,ymesh.^2));
r = sqrt(xmesh.^2 +ymesh.^2);


mask = zeros(size(xmesh));
% mask(r<R1 | r>R2) = 1;
if ( CENTER_SQUARE )
    mask = 1./(1 + exp(-(rs-R1)/S1)) + 1./(1 + exp((r-R2)/S2))-1;
else
    mask = 1./(1 + exp(-(r-R1)/S1)) + 1./(1 + exp((r-R2)/S2))-1;
end

    
if ( 1 )
    figure
    imshow(uint8(double(illusionimage).*mask))
end

imwrite(uint8(double(illusionimage).*mask), 'TestIllusoryTiltImage.tiff');