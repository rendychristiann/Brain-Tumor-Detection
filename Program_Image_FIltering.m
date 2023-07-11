clc;                % clear the command window.
close all;          % close all figures
imtool close all;   % close all imtool figures.
clear;              % erase all existing variables.
warning off
%% Get MRI image from local storage
[path, nofile] = imgetfile();
if nofile
    msgbox(sprintf('Image Not Found'), 'Error', 'Warning');
    return
end

MRI_image = imread(path);
figure
imshow(MRI_image); 
title('MRI Image');
    
%% Image Filtering 
MRI_image = imresize(MRI_image,[224,224]);
MRI_image= im2gray(MRI_image); % Gray Scaling
MRI_image = medfilt2(MRI_image); % Median Filter
MRI_image = wiener2(MRI_image,[5 5]); % Wiener Filter
MRI_image= im2bw(MRI_image,.6);     %Binarize Image
figure
imshow(MRI_image);
title('Filtered Image');
    
%% Predefined Sobel horizontal edge-emphasizing Filter
hy = -fspecial('sobel');
hx = hy';
Iy = imfilter(double(MRI_image), hy, 'replicate');
Ix = imfilter(double(MRI_image), hx, 'replicate');

gradmag = sqrt(Ix.^2 + Iy.^2);
L = watershed(gradmag);
Lrgb = label2rgb(L);

figure,
    imshow(Lrgb); 
    title('Watershed segmented image');
    
%% Image morphological structuring 
se = strel('disk', 20);  % se - Structuring Element
Io = imopen(MRI_image, se);                 % opening (erosi+dilasi) objek
Ie = imerode(MRI_image, se);                % erosi/pengecilan ukuran objek

Iobr = imreconstruct(Ie, MRI_image);        % rekonstruksi morfologis gambar
Iobrd = imdilate(Iobr, se);                 % dilasi/perbesaran gambar
Iobrcbr = imreconstruct(imcomplement(Iobrd), imcomplement(Iobr));
Iobrcbr = imcomplement(Iobrcbr);            % complement nilai pixel objek

I2 = MRI_image;
fgm = imregionalmax(Iobrcbr);               % peroleh titik-titik maksimum lokal objek 
I2(fgm) = 255;                              % set nilai maksimum pixel = 255

se2 = strel(ones(5,5));
fgm2 = imclose(fgm, se2);
fgm3 = imerode(fgm2, se2);
fgm4 = bwareaopen(fgm3, 20);

I3 = imerode(MRI_image, se);
bw = im2bw(Iobrcbr);
figure
    imshow(bw);
    title('only tumor');
%% -----------------------------------------------------------------
