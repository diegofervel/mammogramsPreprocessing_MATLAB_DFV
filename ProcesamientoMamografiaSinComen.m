clc; clear all; close all;

% IMAGEN
[NombreI,PathName] = uigetfile('*.*','Seleccione el archivo imagen');
I=imread(NombreI);

%% IMAGEN DE ENTRADA
figure(1)
imshow(I);title('Input Image (Digital Mammogram)');

InfoI=imfinfo(NombreI);

umbral = 64;
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


%% IMAGEN BINARIZADA
BW = imbinarize(I);

%% CLOSING
len = 20;
deg = 135;
SE1 = strel('line',len,deg); %Elemento de estructuración morfológica
closeBW = imclose(BW,SE1); %Cierre morfológico en la escala de grises o la imagen binaria I


%% EROSION
SE2 = strel('disk', 1); %4
Erosion1 = imerode(closeBW,SE2);


%% EROSION AGAIN
SE3 = strel('line',5,45); %Elemento de estructuración morfológica
Erosion2 = imerode(Erosion1,SE3);


%% IMFILL
Erosion2 = imfill(Erosion2,'holes');
Erosion2 = logical(Erosion2);


%% BIGGEST AREA
bigArea = bwareafilt(Erosion2, 1);
bigArea = bwconvhull(bigArea);
bigArea = uint8(bigArea);


%% Esta es la que voy a utilizar para detectar el pectoral:
SegmentedImage = bigArea.*I;

figure(2)
imshow(SegmentedImage);title('First Segmented Image');


%% Todas a la derecha:
[rows, columns] = find(SegmentedImage);
row1 = min(rows);
row2 = max(rows);
col1 = min(columns);
col2 = max(columns);
cropImage = SegmentedImage(row1:row2, col1:col2); % Crop binary image bigArea


%% CROPPED IMAGE
[nR,nC] = size(cropImage);
sumFirst = sum(cropImage(:,1:20));
sumLast = sum(cropImage(:,nC-19:nC));
if sumFirst>sumLast
    orientation = 'right'
    r_orientedImage = SegmentedImage;
else
    orientation = 'left'
    r_orientedImage = fliplr(SegmentedImage);
end


%% Eliminación del pectoral:

x = find(r_orientedImage);

r_orientedImageLlenos = r_orientedImage(x);

maxVal = max(r_orientedImageLlenos);
maxVal = double(maxVal);
x = entropy(r_orientedImageLlenos);

%% Si entropía alta (imagen con más variaciones) pongo umbral más bajo, si es más plana, pongo umbral más alto:
%La idea es que donde esté más desordenado es porque no hay pectoral, o sea
%que las intensidades deben ser algo bajas, por eso pongo el umbral más bajo
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

umbral = floor(maxVal*porcUmbral); %maxValPix/2;

highPixelsImage = r_orientedImage;
[f,c]=size(highPixelsImage);
limRows = f; %floor(f*1);
limColumns = c; %floor(c*1);

for i=1:limRows
    for j=1:limColumns
        distance = sqrt( (i-1)^2 + (j-1)^2 ); %distancia al origen
        distance2 = sqrt( (i-(limRows*0.6))^2 + (j-(limColumns*0.8))^2 );
         if  (highPixelsImage(i,j)>umbral) && (highPixelsImage(i,j)<=255) %highPixelsImage(i,j) > umbral
            if  distance < distance2
                highPixelsImage(i,j) = 0;
            end
         end
    end
end

%% PIXELS WITH LESS EUCLIDEAN DISTANCE TO ORIGIN AND IN THE UMBRAL RANGES
llenohueco = imfill(highPixelsImage,'holes');

%% IMFILL
structElement = strel('disk', 10); %4
binLlenoHueco = imbinarize(llenohueco);

%% OPENING
binLlenoHueco = imopen(binLlenoHueco,structElement);
binLlenoHueco = bwconvhull(binLlenoHueco);
binLlenoHueco = uint8(binLlenoHueco);
%% MASKING
defini = binLlenoHueco.*r_orientedImage;

%% BINARIZE
defini = imbinarize(defini);

%% CLOSING
defini = imclose(defini,structElement);

%% BIGAREA
defini = bwareafilt(defini, 1);
defini = bwconvhull(defini);
defini = uint8(defini);


%% MASKING
defini = defini.*r_orientedImage;


%% Corto el resultado (Crop):
cropDefini = defini;
cropDefini = adapthisteq(cropDefini);
%cropDefini = imbinarize(cropDefini,0.7);
%cropDefini = uint8(cropDefini);

%% FINAL CROP
%cropDefini = imresize(cropDefini,[512 512]);
figure(3)
imshow(cropDefini);title('Final Crop');

%% OJO, NO DESCARTAR IMPLEMENTAR TRANSFORMACIÓN LOGARÍTMICA PARA UNA MEJOR DETECCIÓN DEL CONTORNO DE LA IMAGEN!!!!!!!!!!!!!!!

