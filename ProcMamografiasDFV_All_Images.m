clc; clear all; close all;

%Seleccionar archivo de imágenes

% IMAGEN
[NombreI,PathName] = uigetfile('*.*','Seleccione el archivo imagen');
%[NombreI,PathName] = uigetfile('C:\Program Files\MATLAB\R2013a\toolbox\images\imdemos\*.*','Seleccione el archivo imagen');
%Cargar imagen
I=imread(NombreI);

%% IMAGEN DE ENTRADA
figure(1)
imshow(I);title('Input Image (Digital Mammogram)');

%Información Imagen
InfoI=imfinfo(NombreI);

%Rota img la izquierda
%I = imrotate(I,90);

umbral = 64;
%function y = binarizacion(imagen,umbral)
%im=imread(NombreI);
imD=double(I);
[f,c]=size(imD);
for i=1:f
    for j=1:c
        if imD(i,j)<=umbral
            nuevaI(i,j) = 0;
        else
            nuevaI(i,j) = 255;
        end
    end
end
imB = uint8(nuevaI);
%imshow(imB);
%BW = nuevaI; 

%% IMAGEN BINARIZADA
BW = imbinarize(I);
% figure(2)
% imshow(BW);title('Binarized Image');


%SE1 = strel('disk', 4);
%SE1.Neighborhood


%% CLOSING
len = 20;
deg = 135;
SE1 = strel('line',len,deg); %Elemento de estructuración morfológica
closeBW = imclose(BW,SE1); %Cierre morfológico en la escala de grises o la imagen binaria I
% figure(3)
% imshow(closeBW);title('Closing');

%% EROSION
SE2 = strel('disk', 1); %4
Erosion1 = imerode(closeBW,SE2);
% figure(4)
% imshow(Erosion1);title('Erosion');

%% EROSION AGAIN
SE3 = strel('line',5,45); %Elemento de estructuración morfológica
Erosion2 = imerode(Erosion1,SE3);
% figure(5)
% imshow(Erosion2);title('Erosion again');

%% IMFILL
Erosion2 = imfill(Erosion2,'holes');
% figure(6)
% imshow(Erosion2);title('Imfill');

%Border = Erosion1 - Erosion2; 
%R = imfuse(I,Border,'diff'); %diff , montage
%Border = uint8(Border);
%R = I + Border;
Erosion2 = logical(Erosion2);


%% BIGGEST AREA
bigArea = bwareafilt(Erosion2, 1);
% figure(7)
% imshow(bigArea);title('Biggest Area');
bigArea = bwconvhull(bigArea);
% figure(17)
% imshow(bigArea);

bigArea = uint8(bigArea);


%holesFilled = imfill(bigArea,'holes');
%holesFilledInt = uint8(holesFilled*255);

%% Esta es la que voy a utilizar para detectar el pectoral:
SegmentedImage = bigArea.*I;
%% SEGMENTED WITH PECTORAL
% figure(8)
% imshow(SegmentedImage);title('Segmented with Pectoral');

%% Todas a la derecha:
[rows, columns] = find(SegmentedImage);
row1 = min(rows);
row2 = max(rows);
col1 = min(columns);
col2 = max(columns);
cropImage = SegmentedImage(row1:row2, col1:col2); % Crop binary image bigArea


%% CROPPED IMAGE
% figure(9)
% imshow(cropImage);title('Cropped Image');
% cropEqualizedI = equalizedI(row1:row2, col1:col2); %Crop equializedI
% cropEqualized2_I = adapthisteq(cropEqualizedI);

[nR,nC] = size(cropImage);
sumFirst = sum(cropImage(:,1:20));
sumLast = sum(cropImage(:,nC-19:nC));
if sumFirst>sumLast
    orientation = 'right'
    %r_orientedImage = cropImage;
    r_orientedImage = SegmentedImage;
else
    orientation = 'left'
    %r_orientedImage = fliplr(cropImage);
    r_orientedImage = fliplr(SegmentedImage);
%     cropEqualizedI = fliplr(cropEqualizedI);
%     cropEqualizedI = fliplr(cropEqualizedI);
%     cropEqualized2_I = fliplr(cropEqualized2_I);
end

%% RIGHT ORIENTED IMAGE
% figure(10)
% imshow(r_orientedImage);title('Right Oriented Image');

%% Eliminación del pectoral:

%r_orientedImage = adapthisteq(r_orientedImage);

%minValPix = min(r_orientedImage(:));
%maxValPix = max(r_orientedImage(:));

%%% Aquí hallaré promedio de valores para ver dónde se mueve

% x = entropy(r_orientedImage)

%r_orientedImage = imsharpen(r_orientedImage);

x = find(r_orientedImage);
%x = double (x);
r_orientedImageLlenos = r_orientedImage(x);
%r_orientedImageLlenos = double(r_orientedImageLlenos);
%cropImage = SegmentedImage(row1:row2, col1:col2); % Crop binary image bigArea

maxVal = max(r_orientedImageLlenos);
maxVal = double(maxVal);
x = entropy(r_orientedImageLlenos);

%% Si entropía alta (imagen con más variaciones) pongo umbral más bajo, si es más plana, pongo umbral más alto:
%x = x*100
if (x>7.1) && (x<8)
    porcUmbral = 0.4;
elseif (x>6.5) && (x<7.1)
    porcUmbral = 0.7;
elseif (x>6.2) && (x<6.5)
     porcUmbral = 0.8;
else
    porcUmbral = 0.9;
end
%porcUmbral = 0.4;
umbral = floor(maxVal*porcUmbral); %maxValPix/2;

highPixelsImage = r_orientedImage;
[f,c]=size(highPixelsImage);
limRows = f; %floor(f*1);
limColumns = c; %floor(c*1);

for i=1:limRows
    for j=1:limColumns
        distance = sqrt( (i-1)^2 + (j-1)^2 );
        %distance2 = sqrt( (i-floor(f*0.6))^2 + (j-floor(c*0.4))^2 );
        %distance2 = sqrt( (i-(limRows*0.3))^2 + (j-(limColumns*1))^2 );
        distance2 = sqrt( (i-(limRows*0.6))^2 + (j-(limColumns*0.8))^2 );
         if  (highPixelsImage(i,j)>umbral) && (highPixelsImage(i,j)<=255) %highPixelsImage(i,j) > umbral
            if  distance < distance2
                highPixelsImage(i,j) = 0;
            end
         end
    end
end

%% PIXELS WITH LESS EUCLIDEAN DISTANCE TO ORIGIN AND IN THE UMBRAL RANGES
% figure(11)
% imshow(highPixelsImage);title('Euclidean and Umbral');


llenohueco = imfill(highPixelsImage,'holes');
%% IMFILL
% figure(12)
% imshow(llenohueco);title('Final Imfill');

% len = 30;
% deg = 180;
%structElement = strel('line',len,deg); %Elemento de estructuración morfológica
structElement = strel('disk', 10); %4
% llenohueco = imopen(llenohueco,structElement);
binLlenoHueco = imbinarize(llenohueco);
%% BINARIZE
% figure(13)
% imshow(binLlenoHueco);title('Final Imfill Binarized');
%structElement = strel('disk', 5); %4
%binLlenoHueco = imerode(binLlenoHueco,structElement);
%% OPENING
binLlenoHueco = imopen(binLlenoHueco,structElement);
% figure(14)
% imshow(binLlenoHueco);title('Final Imfill Binarized Opening');
%binLlenoHueco = imclose(binLlenoHueco,structElement);
binLlenoHueco = bwconvhull(binLlenoHueco);
binLlenoHueco = uint8(binLlenoHueco);
%% MASKING
defini = binLlenoHueco.*r_orientedImage;
% figure(15)
% imshow(defini);title('Masking (Almost Definitive)');
%% BINARIZE
defini = imbinarize(defini);
% figure(16)
% imshow(defini);title('Binarized Masked');
%% CLOSING
defini = imclose(defini,structElement);
% figure(17)
% imshow(defini);title('Closing Binarized Masked');

%% BIGAREA
defini = bwareafilt(defini, 1);
% figure(18)
% imshow(defini);title('Bigger Area');
defini = bwconvhull(defini);
defini = uint8(defini);

%% MASKING
defini = defini.*r_orientedImage;
% figure(19)
% imshow(defini);title('Final Masking');

% defini = uint8(defini);
% defini = adapthisteq(defini);

%% Corto el resultado (Crop):
% [roFi, coFi] = find(defini);
% roFi1 = min(roFi);
% roFi2 = max(roFi);
% coFi1 = min(coFi);
% coFi2 = max(coFi);
% cropDefini = defini(roFi1:roFi2, coFi1:coFi2); % Crop binary image bigArea
cropDefini = defini;
cropDefini = adapthisteq(cropDefini);

%cropDefini = imbinarize(cropDefini);

%% FINAL CROP
figure(20)
imshow(cropDefini);title('Final Crop');

%% DEFINITIVE - FINAL IMAGE!!!
%cropDefini = adapthisteq(cropDefini);
%cropDefini = histeq(cropDefini);

%cropDefini = 255-cropDefini;
%cropDefini = medfilt2(cropDefini); 

% umb = 150;
% 
% [f,c]=size(cropDefini);
% for i=1:f
%     for j=1:c
%         if cropDefini(i,j)<=umb
%             cropDefini(i,j) = 0;
%         end
%     end
% end

%cropDefiniNew=uint8(cropDefiniNew);

cropDefini = imresize(cropDefini,[512 512]);
% figure(21)
% imshow(cropDefini);title('HISTEQ (FINAL SEGMENTED IMAGE)');




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Visualizar imágenes
% figure(1)
% subplot(2,4,1); 
% imshow(I);title('Imagen de Entrada');
% subplot(2,4,2); 
% imshow(BW);title('Imagen Binarizada');
% subplot(2,4,3); 
% imshow(closeBW);title('Imagen Morfológicamente Cerrada');
% subplot(2,4,4); 
% imshow(Erosion1);title('Imagen Morf Cerrada Erosionada 1');
% subplot(2,4,5); 
% imshow(Erosion2);title('Imagen Morf Cerrada Erosionada 2');
% subplot(2,4,6); 
% imshow(bigArea*255);title('Imagen Area mas Grande');
% subplot(2,4,7); 
% imshow(SegmentedImage);title('Segmented Image');
% subplot(2,4,8); 
% imshow(r_orientedImage);title('Cropped & Right Oriented');
% 
% figure(2)
% subplot(1,3,1); 
% imshow(I);title('Input Image');
% subplot(1,3,2); 
% %imshow(r_orientedImage);title('Cropped & Right Oriented');
% imshow(cropImage);title('Cropped');
% subplot(1,3,3); 
% imshow(highPixelsImage);title('High Pixels Image');
