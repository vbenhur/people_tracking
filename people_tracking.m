%test
clear
sName='../../../Videos/Untitled14-uncompressed.avi';
fInfo=aviinfo(sName);
d=aviread(sName,1);
h=mexCvBSLib(d.cdata);%Initialize
t=mexCvBSLib(d.cdata);%Initialize

mexCvBSLib(d.cdata,h,[0.01 4*4 1 0.2]);%set parameters
%mexCvBSLib(d.cdata,t,[0.01 24 1 0.2]);%set parameters


hVideoOrig = vision.VideoPlayer('Name', 'Original', 'Position',[100 500 400 400]);
hVideoMask = vision.VideoPlayer('Name', 'Mask', 'Position', [900 500 400 400]);
hVideoMask2 = vision.VideoPlayer('Name', 'fg_binary', 'Position', [1300 500 400 400]);
%hVideoMask3 = vision.VideoPlayer('Name', 'Mask3', 'Position', [100 50 400 400]);
hVideoBound = vision.VideoPlayer('Name', 'Bound', 'Position', [500 500 400 400]);

% Create a blob analysis System object to segment cars in the video.
hblob = vision.BlobAnalysis( ...
                    'CentroidOutputPort', false, ...
                    'AreaOutputPort', true, ...
                    'BoundingBoxOutputPort', true, ...
                    'EccentricityOutputPort', false, ...   
                    'OutputDataType', 'single', ...
                    'MinimumBlobArea', 450, ...
                    'MaximumBlobArea', 86000, ...
                    'MaximumCount', 80);

% Create System object for drawing the bounding boxes around detected cars.
hshapeins = vision.ShapeInserter( ...
            'BorderColor', 'Custom', ...
            'CustomBorderColor', [255 255 0]);   
        
% Create and configure a System object to write the number of cars being
% tracked.
htextins = vision.TextInserter( ...
        'Text', '%4d', ...
        'Location',  [1 1], ...
        'Color', [255 255 255], ...
        'FontSize', 12);
    
    fg_binary =0;
    line_column = 0; % Define region of interest (ROI)
    count = 0;

    
% Creare un video dal Matlab
%writerObj = VideoWriter('Videos-Finais/Untitled14-Final.avi','Uncompressed AVI');
writerObj = VideoWriter('Videos-Finais/Untitled14-Final-Foreground.avi','Uncompressed AVI');
%writerObj = VideoWriter('Videos-Finais/Untitled9-Final_FILTER_D4_E3.avi','Uncompressed AVI');
writerObj.FrameRate = 30;
open(writerObj);
set(gca,'nextplot','replacechildren');
set(gcf,'Renderer','zbuffer');

%---------------

%Set dilatation and erosion parameters

 SE_DILATATION = strel('disk', 4);
 SE_EROSION = strel('disk', 3);
 SE2_EROSION = strel('disk', 1);

for i=1:fInfo.NumFrames
    d=aviread(sName,i);
    
    imMask=mexCvBSLib(d.cdata,h); %con shadow removal
%    imMask2=mexCvBSLib(d.cdata,t); % senza shadow removal
   
    %   imshow(imMask);
  
    % Transform imMask in binary image
    fg_binary = im2bw(imMask);
    
    % Apply median filter
    FILTER_DOT = medfilt2(fg_binary); 
   
   % EROSION_DISK = imerode(FILTER_DOT, SE2_EROSION);
    
   % Apply segmentations
    %DILATATION_DISK = imdilate(EROSION_DISK, SE_DILATATION);
    DILATATION_DISK = imdilate(FILTER_DOT, SE_DILATATION);
    EROSION_DISK = imerode(DILATATION_DISK, SE_EROSION);
    
    fg_binary = EROSION_DISK;
    imMask2 = fg_binary;
    
    % Transform binary image in rgb ( 0 or 255 )
    record= 255 * uint8(fg_binary);

    % Estimate the area and bounding box of the blobs in the foreground
    % image
    [area, bbox] = step(hblob, fg_binary);
    
    image_out = d.cdata;
    %image_out(:,160:161,:) = 255;  % Count cars only below this white line
    image_out(1:15,1:30,:) = 0;  % Black background for displaying count
    
    Idx = bbox(:,1) > line_column; % Select boxes which are in the ROI.

    % Based on dimensions, exclude objects which are not cars. When the
    % ratio between the area of the blob and the area of the bounding box
    % is above 0.4 (40%) classify it as a car.
    ratio = zeros(length(Idx),1);
    ratio(Idx) = single(area(Idx,1))./single(bbox(Idx,3).*bbox(Idx,4));
    %ratiob=ratio;
    ratiob = ratio > 0.3;
    count = int32(sum(ratiob));    % Number of people
   % contador = 
    bbox(~ratiob,:) = int32(-1);

    % Draw bounding rectangles around the detected cars.
    image_out = step(hshapeins, image_out, bbox);

    % Display the number of cars tracked and a white line showing the ROI.
    image_out = step(htextins, image_out, count);
    
    %--------- Record video from matlab
   % frame = image_out;
    frame =imMask;
     writeVideo(writerObj,frame);


     
     % Show videos
     step(hVideoOrig, d.cdata);          % Original video
     step(hVideoMask, imMask);          % Mask video
     step(hVideoMask2, imMask2);          % Mask video
     step(hVideoBound,  image_out);      % Bounding boxes around cars

end
mexCvBSLib(h);%Release memory
close(writerObj);

%mexCvBSLib(t);%Release memory