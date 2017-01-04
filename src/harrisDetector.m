function query_keypoints = harrisDetector (query_image, current_keypoints)
    debug_with_figures = false;

    % Parameters form exercise 3.
    harris_patch_size = 9;
    harris_kappa = 0.08;
    nonmaximum_supression_radius = 8;
    
    % Other parameters.
    num_keypoints = 50;
    cols = 4;
    rows = 3;
    
%             selected_kps = selectKeypoints(lean_scores(h_indices_limits(h):h_indices_limits(h+1),...
%                                                                                 w_indices_limits(w):w_indices_limits(w+1)), ...
%                                                             num_keypoints, nonmaximum_supression_radius);
    
    algorithm = 1;
    if (algorithm == 1) 
        query_keypoints = customUniformHarrisDetector (query_image, num_keypoints, cols, rows);
            if (debug_with_figures)
                figure(23);
                imshow(query_image); hold on;
                plot(query_keypoints(2,:),...
                        query_keypoints(1,:),...
                        'bx', 'Linewidth', 3);
                title('Whole image with Custom Uniform keypoints');
                hold off;
            end
    elseif (algorithm ==2)
        query_keypoints = strongestHarrisDetector(query_image, cols*rows*num_keypoints);
           if (debug_with_figures)
                figure(21);
                imshow(query_image); hold on;
                plot(query_keypoints(2,:),...
                        query_keypoints(1,:),...
                        'bx', 'Linewidth', 3);
                title('Whole image with Strongest keypoints');
                hold off;
           end 
    elseif (algorithm == 3)
        query_keypoints = uniformHarrisDetector(query_image, cols*rows*num_keypoints);
            if (debug_with_figures)
                figure(22);
                imshow(query_image); hold on;
                plot(query_keypoints(2,:),...
                        query_keypoints(1,:),...
                        'bx', 'Linewidth', 3);
                title('Whole image with Uniform keypoints');
                hold off;
            end
    else
        fprintf('No correct Harris Detector selected');
    end
end

% Uniform selection of harris corners on the image. The image is divided
% in a quadrant of cols columns and rows rows and then num_keypoints are
% selected PER BIN. It can be that the bin has less keypoints than selected
% depending on the min quality given to the Harris detector.
function query_keypoints = customUniformHarrisDetector (query_image, num_keypoints, cols, rows)
    debug_with_figures = false;
    
    width = size(query_image, 2);
    height = size(query_image, 1);
    
    % Determine limits of the image bins
    w_indices_limits = ones(1,cols+1);
    for i=1:cols
        w_indices_limits(i+1) = floor(width/cols*i);
    end
    h_indices_limits = ones(1,rows+1);
    for i=1:rows
        h_indices_limits(i+1) = floor(height/rows*i);
    end
    
    % TRY to not take keypoints close to the borders of the image, to do so
    % just crop the image...
    
    % Extract keypoints per bin
    query_keypoints = zeros(2, cols*rows*num_keypoints);
    ultimate_size = 0;
    for w = 1:cols
        for h = 1:rows
            % Crop image
            image_bin = query_image(h_indices_limits(h):h_indices_limits(h+1),...
                                                     w_indices_limits(w):w_indices_limits(w+1));
            % Compute corners
            corners = detectHarrisFeatures(image_bin);
            % Select strongest
            strongest = corners.selectStrongest(num_keypoints).Location;
            best_keypoints = round(flipud(strongest'));
            % Store keypoints
            query_keypoints(:, ultimate_size+1:ultimate_size+size(best_keypoints, 2))  = ...
            [best_keypoints(1,:)+h_indices_limits(h)-1; best_keypoints(2,:)+w_indices_limits(w)-1];
            
            % Debug keypoints taken per bin
            if (debug_with_figures)
                figure(20);
                subplot(1, 4, [1 2]);
                imshow(query_image); hold on;
                plot(query_keypoints(2,ultimate_size+1:ultimate_size+size(best_keypoints, 2)),...
                    query_keypoints(1,ultimate_size+1:ultimate_size+size(best_keypoints, 2)),...
                    'bx', 'Linewidth', 3);
                title('Whole image with keypoints');
                hold off;
                subplot(1, 4, [3 4]);
                imshow(image_bin);
                hold on;
                plot(best_keypoints(2,:), best_keypoints(1,:), 'bx', 'Linewidth', 3);
                title('Bin image with keypoints');
                hold off;
            end
            % Number of keypoints that have been selected in the end
            ultimate_size = ultimate_size+size(best_keypoints, 2);
        end
    end
    % Remove extra 0s of query_keypoints
    query_keypoints = query_keypoints(:, 1:ultimate_size);
end

function query_keypoints = uniformHarrisDetector(query_image, num_keypoints)
    debug_with_figures = false;
    % Compute corners
    corners = detectHarrisFeatures(query_image);
    % Select strongest uniformly
    uniform_strongest = corners.selectUniform(num_keypoints, size(query_image));
    if(debug_with_figures)
        figure(31);
        imshow(query_image); hold on;
        plot(uniform_strongest);
        title('Whole image with  UNIFORM all keypoints');
        hold off;
    end
    query_keypoints = round(flipud(uniform_strongest.Location'));
end

function query_keypoints = strongestHarrisDetector(query_image, num_keypoints)
    debug_with_figures = false;
    % Compute corners
    corners = detectHarrisFeatures(query_image);
    % Select strongest
    strongest = corners.selectStrongest(num_keypoints);
    if(debug_with_figures)
        figure(31);
        imshow(query_image); hold on;
        plot(strongest);
        title('Whole image with STRONGEST keypoints');
        hold off;
    end
    query_keypoints = round(flipud(strongest.Location'));
end

function new_scores = leanerScores (scores, tracked_keypoints, r)
    temp_scores = padarray(scores, [r r]);
    tracked_keypoints = ceil(tracked_keypoints)+r; % NOT sure whether to use floor or round, I
    % pick ceil to make sure I don't run into non-positive indices
    % afterwards..
    % Remove already followed keypoints
    for i = 1:size(tracked_keypoints, 2)
        temp_scores(tracked_keypoints(1,i)-r:tracked_keypoints(1,i)+r,...
                              tracked_keypoints(2,i)-r:tracked_keypoints(2,i)+r)...
                              = zeros(2*r+1, 2*r+1);
    end
    new_scores = temp_scores(r+1:end-r, r+1:end-r);
end

