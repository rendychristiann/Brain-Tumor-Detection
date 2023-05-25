clc;                % clear the command window.
close all;          % close all figures
imtool close all;   % close all imtool figures.
clear;              % erase all existing variables.
warning off

%% Get MRI image from local storage
global I_Raw 

[path, nofile] = imgetfile();
if nofile
    msgbox(sprintf('Image Not Found'), 'Error', 'Warning');
    return
end

I_Raw = imread(path);
I_Raw = im2double(I_Raw);
I_Raw = im2gray(I_Raw);
I_Information = imfinfo(path);
subplot(2,2,1)
imshow(I_Raw);
title('MRI Image');

%% Image Filtering 
I_Filter = imbinarize(I_Raw, 'adaptive', 'Sensitivity', 0.59);
I_Filter = medfilt2(I_Filter, [5,5]);
I_Filter = wiener2(I_Filter,[5 5]);
SE_Filter = strel('disk', 2);
I_Filter = imclose(I_Filter,SE_Filter);
subplot(2,2,2)
imshow(I_Filter)
title('Filtered Image');

%% Pre-Generate Elliptical Mask
X_Size = size(I_Raw, 2);
Y_Size = size(I_Raw, 1);
X_Center = Y_Size/2;
Y_Center = Y_Size/2;
X_Radius = X_Center - 40;
Y_Radius = Y_Center - 50;
[Col, Row] = meshgrid(1:X_Size,1:Y_Size);
Mask = ((Row - Y_Center).^2 ./ Y_Radius^2) + ((Col - X_Center).^2 ./ X_Radius^2) <= 1;

%% Tumor Isolation
global I_Detect
I_Detect = logical(I_Filter .* Mask);
I_Detect = bwareafilt(I_Detect, [700 4000]);
SE_Detect = strel('disk', 6);
I_Detect = imclose(I_Detect,SE_Detect);
I_Detect = imfill(I_Detect, 'holes');
subplot(2,2,3)
imshow(I_Detect)
title('Tumor Founded')

%% Plot outline of tumor onto original MRI image
subplot(2,2,4)
imshow(I_Raw,[]);
title('MRI with outlined Tumor');

hold on
I_Idx = bwboundaries(I_Detect, 'noholes');
for k = 1:length(I_Idx)
    plot(I_Idx{k}(:,2),I_Idx{k}(:,1), 'y', 'linewidth', 1.5)
end
hold off

