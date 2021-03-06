clc; clear all; close all;

%Seleccionar archivo de imágenes

%% IMAGEN
[NombreI,PathName] = uigetfile('*.*','Seleccione el archivo imagen');
%[NombreI,PathName] = uigetfile('C:\Program Files\MATLAB\R2013a\toolbox\images\imdemos\*.*','Seleccione el archivo imagen');
%Cargar imagen
I=imread(NombreI);

%Información Imagen
InfoI=imfinfo(NombreI);

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
BW = imbinarize(I);
len = 20;
deg = 135;
SE1 = strel('line',len,deg); %Elemento de estructuración morfológica
%SE1 = strel('disk', 4);
%SE1.Neighborhood
closeBW = imclose(BW,SE1); %Cierre morfológico en la escala de grises o la imagen binaria I
SE2 = strel('disk', 1); %4
Erosion1 = imerode(closeBW,SE2);
SE3 = strel('line',5,45); %Elemento de estructuración morfológica
Erosion2 = imerode(Erosion1,SE3);
Erosion2 = imfill(Erosion2,'holes');;

%Border = Erosion1 - Erosion2; 
%R = imfuse(I,Border,'diff'); %diff , montage
%Border = uint8(Border);
%R = I + Border;
Erosion2 = logical(Erosion2);

bigArea = bwareafilt(Erosion2, 1);
bigArea = uint8(bigArea);

%holesFilled = imfill(bigArea,'holes');
%holesFilledInt = uint8(holesFilled*255);

%% Esta es la que voy a utilizar para detectar el pectoral:
SegmentedImage = bigArea.*I;

%% Todas a la derecha:
[rows, columns] = find(SegmentedImage);
row1 = min(rows);
row2 = max(rows);
col1 = min(columns);
col2 = max(columns);
cropImage = SegmentedImage(row1:row2, col1:col2); % Crop binary image bigArea
% cropEqualizedI = equalizedI(row1:row2, col1:col2); %Crop equializedI
% cropEqualized2_I = adapthisteq(cropEqualizedI);

[nR,nC] = size(cropImage);
sumFirst = sum(cropImage(:,1:20));
sumLast = sum(cropImage(:,nC-19:nC));
if sumFirst>sumLast
    orientation = 'right'
    r_orientedImage = cropImage;
else
    orientation = 'left'
    r_orientedImage = fliplr(cropImage);
%     cropEqualizedI = fliplr(cropEqualizedI);
%     cropEqualizedI = fliplr(cropEqualizedI);
%     cropEqualized2_I = fliplr(cropEqualized2_I);
end

%% Eliminación del pectoral:

%r_orientedImage = adapthisteq(r_orientedImage);

minValPix = min(r_orientedImage(:));
maxValPix = max(r_orientedImage(:));

%%% Aquí hallaré promedio de valores para ver dónde se mueve

% x = entropy(r_orientedImage)

x = find(r_orientedImage);
%x = double (x);
r_orientedImageLlenos = r_orientedImage(x);
%r_orientedImageLlenos = double(r_orientedImageLlenos);
%cropImage = SegmentedImage(row1:row2, col1:col2); % Crop binary image bigArea

maxVal = max(r_orientedImageLlenos);
maxVal = double(maxVal);

x = entropy(r_orientedImageLlenos)

%x = x*100
if (x>7.1) && (x<8)
    porcUmbral = 0.6
elseif (x>6.5) && (x<7.1)
    porcUmbral = 0.7
elseif (x>6.2) && (x<6.5)
     porcUmbral = 0.8
else
    porcUmbral = 0.9
end
umbral = floor(maxValPix*porcUmbral); %maxValPix/2;

highPixelsImage = r_orientedImage;
[f,c]=size(highPixelsImage);
limRows = f; %floor(f*1);
limColumns = c; %floor(c*1);

for i=1:limRows
    for j=1:limColumns
        distance = sqrt( (i-1)^2 + (j-1)^2 );
        %distance2 = sqrt( (i-floor(f*0.6))^2 + (j-floor(c*0.4))^2 );
        distance2 = sqrt( (i-limRows)^2 + (j-limColumns)^2 );
         if  distance < distance2
            if highPixelsImage(i,j) > umbral
                highPixelsImage(i,j) = 0;
            end
         end
    end
end

llenohueco = imfill(highPixelsImage,'holes');
% len = 30;
% deg = 180;
%structElement = strel('line',len,deg); %Elemento de estructuración morfológica
structElement = strel('disk', 10); %4
% llenohueco = imopen(llenohueco,structElement);
binLlenoHueco = imbinarize(llenohueco);
%structElement = strel('disk', 5); %4
%binLlenoHueco = imerode(binLlenoHueco,structElement);
binLlenoHueco = imopen(binLlenoHueco,structElement);
%binLlenoHueco = imclose(binLlenoHueco,structElement);
binLlenoHueco = uint8(binLlenoHueco);
defini = binLlenoHueco.*r_orientedImage;

defini = imbinarize(defini);
defini = imclose(defini,structElement);
defini = bwareafilt(defini, 1);
defini = uint8(defini);
defini = defini.*r_orientedImage;

% defini = uint8(defini);
% defini = adapthisteq(defini);

%Corto el resultado (Crop):
[roFi, coFi] = find(defini);
roFi1 = min(roFi);
roFi2 = max(roFi);
coFi1 = min(coFi);
coFi2 = max(coFi);
cropDefini = defini(roFi1:roFi2, coFi1:coFi2); % Crop binary image bigArea

%cropDefini = adapthisteq(cropDefini);
%cropDefini = histeq(cropDefini);

%cropDefini = 255-(cropDefini(:,:));

[f,c]=size(cropDefini);
limRows = f; %floor(f*1);
limColumns = c; %floor(c*1);

umbral = 185; %maxValPix/2;

for i=1:limRows
    for j=1:limColumns
         if  (cropDefini(i,j) < umbral)
             cropDefini(i,j) = 0;
         end
    end
end

%cropDefini = adapthisteq(cropDefini);

%cropDefini = medfilt2(cropDefini); 

figure(11)
imshow(cropDefini);
title('Imagen Final - Procesada');



% 
% llenohueco = imcomplement(llenohueco);
% 
% binHighPixelsImage = uint8(binHighPixelsImage);
% llenohueco = uint8(binHighPixelsImage);
% 
% figure(11)
% imshow(binHighPixelsImage);
% title('Ah bueee');

% pix_1 = [1,1];
% pix_2 = [p21,p22];
%distance = sqrt( (i-1)^2 + (j-1)^2 );
    
    

%max - min / 2;





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % 
% % % %equalizedI = ecualizah(SegmentedImage);
% % % %equalizedI = histeq(SegmentedImage);
% % % equalizedI = adapthisteq(SegmentedImage);
% % % 
% % % 
% % % %regionprops
% % % 
% % % [rows, columns] = find(bigArea);
% % % row1 = min(rows);
% % % row2 = max(rows);
% % % col1 = min(columns);
% % % col2 = max(columns);
% % % cropImage = bigArea(row1:row2, col1:col2); % Crop binary image bigArea
% % % cropEqualizedI = equalizedI(row1:row2, col1:col2); %Crop equializedI
% % % cropEqualized2_I = adapthisteq(cropEqualizedI);
% % % 
% % % [nR,nC] = size(cropImage);
% % % sumFirst = sum(cropImage(:,1:5));
% % % sumLast = sum(cropImage(:,nC-4:nC));
% % % if sumFirst>sumLast
% % %     orientation = 'right'
% % % else
% % %     orientation = 'left'
% % %     cropEqualizedI = fliplr(cropEqualizedI);
% % %     cropEqualized2_I = fliplr(cropEqualized2_I);
% % % end
% % % 
% % % %nhood = ones(55,23);
% % % %nhood = ones(15,7);
% % % J = entropyfilt(cropEqualized2_I);
% % % MaxJ = max(max(J(:,:)));
% % % MinJ = min(min(J(:,:)));
% % % 
% % % indPectAprox = find(4.5>J(:,:)>0);
% % % a = length(cropEqualized2_I(:,1));
% % % b = length(cropEqualized2_I(1,:));
% % % cropEqualizedITest = zeros(a,b);
% % % cropEqualizedITest = uint8(cropEqualizedITest);
% % % cropEqualizedITest(indPectAprox) = cropEqualized2_I(indPectAprox);
% % % 
% % % cropEqualizedITest = imfill(cropEqualizedITest,'holes');
% % % 
% % % figure(3)
% % % imshow(cropEqualizedITest);
% % % 
% % % RobertsEdge = edge(cropEqualized2_I,'Roberts','vertical'); 
% % % figure(4)
% % % imshow(cropEqualized2_I);
% % % 
% % % ITestPect = zeros(a,b);
% % % lf = length(ITestPect(:,1));
% % % lf = ceil(lf/2);
% % % lc = length(ITestPect(1,:));
% % % lc = floor(lc/2);
% % % FirstQuarterImage = ones(lf,lc);
% % % ITestPect(1:lf,1:lc) = FirstQuarterImage;
% % % ITestPect = uint8(ITestPect);
% % % %imshow(ITestPect);
% % % 
% % % EntropyFirstQuarter = cropEqualizedITest.*ITestPect;
% % % EntropyFirstQuarter = imfill(EntropyFirstQuarter,'holes');
% % % 
% % % figure(9)
% % % imshow(EntropyFirstQuarter); title('Primer cuarto');
% % % 
% % % umbral = 64;
% % % %function y = binarizacion(imagen,umbral)
% % % %im=imread(NombreI);
% % % imDoub=double(cropEqualizedITest);
% % % [f,c]=size(imDoub);
% % % for i=1:f
% % %     for j=1:c
% % %         if imDoub(i,j)<=umbral
% % %             newI(i,j) = 0;
% % %         else
% % %             newI(i,j) = 255;
% % %         end
% % %     end
% % % end
% % % imB = uint8(newI);
% % % %imshow(imB);
% % % BinICropE = newI; 
% % % 
% % % figure(5)
% % % imshow(BinICropE);
% % % 
% % % SE4 = strel('line',50,45); 
% % % %SE4 = strel('diamond', 18); %4
% % % %Erosion1b = imerode(closeBW2,SE4);
% % % Dilate2 = imdilate(BinICropE,SE4);
% % % 
% % % figure(6)
% % % imshow(Dilate2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Visualizar imágenes
figure(1)
subplot(2,4,1); 
imshow(I);title('Imagen de Entrada');
subplot(2,4,2); 
imshow(BW);title('Imagen Binarizada');
subplot(2,4,3); 
imshow(closeBW);title('Imagen Morfológicamente Cerrada');
subplot(2,4,4); 
imshow(Erosion1);title('Imagen Morf Cerrada Erosionada 1');
subplot(2,4,5); 
imshow(Erosion2);title('Imagen Morf Cerrada Erosionada 2');
subplot(2,4,6); 
imshow(bigArea*255);title('Imagen Area mas Grande');
subplot(2,4,7); 
imshow(SegmentedImage);title('Segmented Image');
subplot(2,4,8); 
imshow(r_orientedImage);title('Cropped & Right Oriented');

figure(2)
subplot(1,3,1); 
imshow(I);title('Input Image');
subplot(1,3,2); 
%imshow(r_orientedImage);title('Cropped & Right Oriented');
imshow(cropImage);title('Cropped');
subplot(1,3,3); 
imshow(highPixelsImage);title('High Pixels Image');

% figure(3)
% imshow(cropImage*255);title('Cropped Image');


%% Grabar Imagen Salida
% [nomfile,path] = uiputfile({'*.jpg;*.tif;*.png;*.gif','All Image Files';...
%           '*.*','All Files' },'Salvar Imagen');
% imwrite(equalizedI,nomfile);