%% LotsDots

classdef LotsDots < handle
    % Handle class means it pointers to /references the undrelying data
    % https://www.mathworks.com/help/matlab/matlab_oop/comparing-handle-and-value-classes.html

    properties

        dots_array;       %The array of dots stored inside

        % Direct input variables
        ID_array          %what type of dot it is (ex. what type of movement)
        lifetime_array    %how long this dot will be on-screen, in secs
        age_array         %how long this dot has already been on screen, in secs
        diameter_array    %size of dot
        colour_array      %colour of dot currently
        location_array    %2D coords of dot
        speed_array       %pixels/frame movement of dot
        world_dims_array  %total area that dot could move in
        refreshHz_array
        moveVec_array     %the assigned movement vector for that dot

        % Variables that get updated later on
        yesFade           %is the dot currently fading away?
        refreshHz_array_inv
        bordersX          %the X bounds of the screen that the dots would appear in
        bordersY          %the Y bounds of the screen that the dots would appear in
        centerX           %center of the screen
        centerY           %center of the screen
        radius            %radius of circle 

        num_dots          %the number of dots in the lotsdots

        OFF_colour        %default colour of dot, when it reincarnates
        ON_colours        %the "on" colour(s) of the dots
        


        movement_type     %what type of movemet (ex. uniform, centre-surround, etc.)

        set_speeds = 2*[0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1]; %The speeds that will be in each nonant

        bord_marg = 2;    %multiplier for the margin around the shape border
        

    end


    methods

        %constructor
        function lotsdots = LotsDots(li, ag, di, co, lo, sp, wo, re, mo, varargin)

            if nargin < 9
                error("Not enough inputs for making LOTS DOTS");
            end

            % How many dots?
            lotsdots.num_dots = numel(li);

            % Carefully craft each dot
            for n = 1:lotsdots.num_dots
                a_dot = Dot(li(n), ag(n), di(n), co(n, :), lo(n,:), sp(n), wo(n,:), re(n));
                dots(n) = a_dot;
            end

            lotsdots.dots_array             = dots;

            lotsdots.lifetime_array         = li;
            lotsdots.age_array              = ag;
            lotsdots.diameter_array         = di;
            lotsdots.colour_array           = co;
            lotsdots.location_array         = lo;
            lotsdots.speed_array            = sp;
            lotsdots.world_dims_array       = wo;
            lotsdots.refreshHz_array        = re;
            lotsdots.refreshHz_array_inv    = 1./re;
            lotsdots.moveVec_array          = mo;

            lotsdots.ON_colours      = repmat([1,1,1], lotsdots.num_dots, 1); %white dots only by default
            lotsdots.OFF_colour      = [0 0 0];
            
            if nargin > 9 % ID array
                lotsdots.ID_array = varargin{1};
            end

            if nargin > 10 % array of alternative colours, corresponding to the ID_array inds in order
                lotsdots.ON_colours = varargin{2};
            end


            

            % lotsdots.bordersX = [lotsdots.world_dims_array(1,3)/3, 2*lotsdots.world_dims_array(1,3)/3, lotsdots.world_dims_array(1,3)];
            % lotsdots.bordersY = [lotsdots.world_dims_array(1,4)/3, 2*lotsdots.world_dims_array(1,4)/3, lotsdots.world_dims_array(1,4)];
            
            % span of circle
            lotsdots.centerX = lotsdots.world_dims_array(1,3)/2;
            lotsdots.centerY = lotsdots.world_dims_array(1,4)/2;
            lotsdots.radius = lotsdots.world_dims_array(1,4)/10; % quarter of screen

            bord_marg = 2;

            lotsdots.bordersX = [lotsdots.centerX - bord_marg*lotsdots.radius, lotsdots.centerX + bord_marg*lotsdots.radius];
            lotsdots.bordersY = [lotsdots.centerY - bord_marg*lotsdots.radius, lotsdots.centerY + bord_marg*lotsdots.radius];
            
            
            % fill the rest of the dot parameter arrays
            for n = 1:lotsdots.num_dots
            
                randX = lotsdots.bordersX(1) + rand(1,1) .* (lotsdots.bordersX(2)-lotsdots.bordersX(1));
                randY = lotsdots.bordersY(1) + rand(1,1) .* (lotsdots.bordersY(2)-lotsdots.bordersY(1));
            
                locations(n, :)     = [randX, randY]; % dot locations filled
            
            end

            lotsdots.location_array = locations;


            lotsdots.movement_type              = 1; % by default

            lotsdots.OFF_colour             = [0 0 0];

        end
    

         % update location => assigned vec from moveVec_array
        function lotsdots = move(lotsdots)

            % How many dots?
            %lotsdots.num_dots = numel(lotsdots.dots_array);

            % Update location with the speed assigned from the previous move_down call
            %lotsdots.location_array = lotsdots.location_array + [lotsdots.speed_array*dot_vec(1), lotsdots.speed_array*dot_vec(2), lotsdots.speed_array*dot_vec(1), lotsdots.speed_array*dot_vec(2)];
            lotsdots.location_array = lotsdots.location_array + lotsdots.moveVec_array; % a num_dots x 4 array bc the outer/inner Xs and Ys are defined

            % All the things that need to be done when moving a Dot
            lotsdots.gen_position_update;

            % Get coords of each dot
            horiz_coords = lotsdots.location_array(:,1);
            verti_coords = lotsdots.location_array(:,2);
            
            % Coords together
            %xy_coords = [horiz_coords'; verti_coords'];


            if lotsdots.movement_type == 1 % Centre-surround

                %% Changing speeds dependent on screen segment
                % Currently middle 9th slower than surround
                % intersect = finding the overlap between the groups

                % Set speed_array to whatever, if necessary
                %lotsdots.speed_array(:) = lotsdots.set_speeds(10);

                % Find inds of where the horizontal coords are inside the circle's X coords
                % and same for Y
                inside_circle = (horiz_coords - lotsdots.centerX).^2 + (verti_coords - lotsdots.centerY).^2 <= lotsdots.radius^2;
  
                %inds5o9 = intersect(intersect(find(lotsdots.bordersX(1) < horiz_coords), find(horiz_coords < lotsdots.bordersX(2))), intersect(find(lotsdots.bordersY(1) < verti_coords), find(verti_coords < lotsdots.bordersY(2))));
                % 

                % % Change the ones within the circle to white
                % lotsdots.colour_array(inside_circle, :) = repmat([255 255 255], sum(inside_circle), 1);
                % 
                % % Change the ones outside the circle to black
                % lotsdots.colour_array(~inside_circle, :) = zeros(sum(~inside_circle), 3);
                % % 

                % colours already correspond to ID, so set them that way
                lotsdots.colour_array(inside_circle, :)   = lotsdots.ON_colours(inside_circle, :);
                lotsdots.colour_array(~inside_circle, :)  = repmat(lotsdots.OFF_colour, sum(~inside_circle), 1);

            end

        end

         % update location => vec
        function lotsdots = move_vec(lotsdots, dot_vec)

            % How many dots?
            lotsdots.num_dots = numel(lotsdots.dots_array);

            % Update location with the speed assigned from the previous move_down call
            lotsdots.location_array = lotsdots.location_array + [lotsdots.speed_array*dot_vec(1), lotsdots.speed_array*dot_vec(2), lotsdots.speed_array*dot_vec(1), lotsdots.speed_array*dot_vec(2)];
            %lotsdots.location_array = lotsdots.location_array + repmat(lotsdots.moveVec_array, 1, 2); % a num_dots x 4 array bc the outer/inner Xs and Ys are defined

            %
            lotsdots.gen_position_update;

            % Get coords of each dot
            horiz_coords = (lotsdots.location_array(:,1) + lotsdots.location_array(:,3)) / 2;
            verti_coords = (lotsdots.location_array(:,2) + lotsdots.location_array(:,4)) / 2;


            if lotsdots.movement_type == 1 % Centre-surround

                %% Changing speeds dependent on screen segment
                % Currently middle 9th slower than surround
                % intersect = finding the overlap between the groups

                lotsdots.speed_array(:) = lotsdots.set_speeds(10);

                % Find inds of where the horizontal coords are inside the circle's X coords
                % and same for Y
                inds5o9 = (horiz_coords - lotsdots.centerX).^2 + (verti_coords - lotsdots.centerY).^2 <= lotsdots.radius^2;
                %inds5o9 = intersect(ismember(horiz_coords, lotsdots.bordersX), ismember(verti_coords, lotsdots.bordersY));

                %inds5o9 = intersect(intersect(find(lotsdots.bordersX(1) < horiz_coords), find(horiz_coords < lotsdots.bordersX(2))), intersect(find(lotsdots.bordersY(1) < verti_coords), find(verti_coords < lotsdots.bordersY(2))));
                
                % Change the ones within the circle to white
                lotsdots.colour_array(inds5o9, :) = repmat([1 1 1], sum(inds5o9), 1);

                % Change the ones outside the circle to black
                lotsdots.colour_array(~inds5o9, :) = zeros(sum(~inds5o9), 3);
                
            end

        end

        function lotsdots = gen_position_update(lotsdots)

            % Update dot age
            lotsdots.age_array = lotsdots.age_array + lotsdots.refreshHz_array_inv;
            % 
            % % Get right coord of dot 
            % horiz_coords = lotsdots.location_array(:, 3);    
            % % Get bottom coord of dot
            % verti_coords = lotsdots.location_array(:, 4);   

            % Get coords of each dot
            horiz_coords = lotsdots.location_array(:,1);
            verti_coords = lotsdots.location_array(:,2);

            % Find the dots that are out-of-bounds
            outBounds_inds = find(verti_coords < lotsdots.bordersY(1) | verti_coords > lotsdots.bordersY(2) ...
                | horiz_coords < lotsdots.bordersX(1) | horiz_coords > lotsdots.bordersX(2));

            % outBounds_inds = find(verti_coords > lotsdots.world_dims_array(1,4) | verti_coords < lotsdots.world_dims_array(1,2) ...
            %     | horiz_coords < lotsdots.world_dims_array(1,1) | horiz_coords > lotsdots.world_dims_array(1,3));

            
            % Find the dots that are too old
            old_inds = find(lotsdots.age_array > lotsdots.lifetime_array);

            % Combine indices of all dots that need to be reincarnated
            reincarnate_inds = [outBounds_inds; old_inds];
            reincarnate_inds = unique(reincarnate_inds, 'sorted');

            % Reincarnate (ie. new location set for) these dots
            if numel(reincarnate_inds) > 0

                % make them the default colour
                %lotsdots.colour_array(reincarnate_inds, :) = repmat(lotsdots.OFF_colour, length(reincarnate_inds), 1);

                % move them to another life (location)
                lotsdots.location_array(reincarnate_inds, :) = lotsdots.reincarnate(reincarnate_inds);

            end

            % Zero out the age of the old dots
            lotsdots.age_array(reincarnate_inds) = 0;

            % % Get updated right coord of dot 
            % horiz_coords = lotsdots.location_array(:, 3);    
            % % Get updated bottom coord of dot
            % verti_coords = lotsdots.location_array(:, 4); 
            
            % % Returns center instead
            % horiz_coords = (lotsdots.location_array(:,1) + lotsdots.location_array(:,3)) / 2;
            % verti_coords = (lotsdots.location_array(:,2) + lotsdots.location_array(:,4)) / 2;

        end

        function reincarnate_coords = reincarnate(lotsdots, outBounds_inds)

            % for n = 1:numel(outBounds_inds)
            % 
            %     outInds = outBounds_inds;
            %     % Random gen X coord
            %     randX = lotsdots.world_dims_array(n, 3)*rand(1,1);
            %     % Random gen Y coord, raised up 1/4 the length of the screen
            %     randY = lotsdots.world_dims_array(n, 4)*rand(1,1);
            % 
            %     reincarnate_coords(n, :) = [randX, randY, randX + lotsdots.diameter_array(n), randY + lotsdots.diameter_array(n)];
            % 
            % end

            % n = 1:numel(outBounds_inds);
            % % Random gen X coord (within the X-bounds of the screen)
            % randX = lotsdots.world_dims_array(n, 3).*rand([numel(outBounds_inds), 1]);
            % % Random gen Y coord (within the Y-bounds of the screen)
            % randY = lotsdots.world_dims_array(n, 4).*rand([numel(outBounds_inds), 1]);

            idx = outBounds_inds(:);
            n   = numel(idx);
        
            % randX = lotsdots.world_dims_array(idx, 3) .* rand(n,1);
            % randY = lotsdots.world_dims_array(idx, 4) .* rand(n,1);

            randX = lotsdots.bordersX(1) + rand(n,1)*(lotsdots.bordersX(2) - lotsdots.bordersX(1));
            randY = lotsdots.bordersY(1) + rand(n,1)*(lotsdots.bordersY(2) - lotsdots.bordersY(1));
        
            % Return the coords
            reincarnate_coords =  [randX, randY];

            
        end


        %% Getters
        function li = get.lifetime_array(lotsdots)
            li = lotsdots.lifetime_array;
        end

        function ag = get.age_array(lotsdots)
            ag = lotsdots.age_array;
        end

        function di = get.diameter_array(lotsdots)
            di = lotsdots.diameter_array;
        end

        function co = get.colour_array(lotsdots)
            co = lotsdots.colour_array;
        end

        function lo = get.location_array(lotsdots)
            lo = lotsdots.location_array;
        end

        function sp = get.speed_array(lotsdots)
            sp = lotsdots.speed_array;
        end

        function wo = get.world_dims_array(lotsdots)
            wo = lotsdots.world_dims_array;
        end

        function re = get.refreshHz_array(lotsdots)
            re = lotsdots.refreshHz_array;
        end

        function mo_type = get.movement_type(lotsdots)
            mo_type = lotsdots.movement_type;
        end

        function mo = get.moveVec_array(lotsdots)
            mo = lotsdots.moveVec_array;
        end
        
        function ON_co = get.ON_colours(lotsdots)
            ON_co = lotsdots.ON_colours;
        end

        function OFF_co = get.OFF_colour(lotsdots)
            OFF_co = lotsdots.OFF_colour;
        end

        %% Setters
        function [lotsdots] = set.lifetime_array(lotsdots, li)
            lotsdots.lifetime_array = li;
        end

        function [lotsdots] = set.age_array(lotsdots, ag)
            lotsdots.age_array = ag;
        end

        function [lotsdots] = set.diameter_array(lotsdots, di)
            lotsdots.diameter_array = di;
        end

        function [lotsdots] = set.colour_array(lotsdots, co)
            lotsdots.colour_array = co;
        end

        function [lotsdots] = set.location_array(lotsdots, lo)
            lotsdots.location_array = lo;
        end

        function [lotsdots] = set.speed_array(lotsdots, sp)
            lotsdots.speed_array = sp;
        end

        function [lotsdots] = set.world_dims_array(lotsdots, wo)
            lotsdots.world_dims_array = wo;
        end

        function [lotsdots] = set.refreshHz_array(lotsdots, re)
            lotsdots.refreshHz_array = re;
        end

        function [lotsdots] = set.movement_type(lotsdots, mo_type)
            lotsdots.movement_type = mo_type;
        end

        function [lotsdots] = set.moveVec_array(lotsdots, mo)
            lotsdots.moveVec_array = mo;
        end

        function [lotsdots] = set.ON_colours(lotsdots, ON_co)
            lotsdots.ON_colours = ON_co;
        end

        function [lotsdots] = set.OFF_colour(lotsdots, OFF_co)
            lotsdots.OFF_colour = OFF_co;
        end

        
    end

    methods(Static) % methods that don't need an object instance to be called


    end

end