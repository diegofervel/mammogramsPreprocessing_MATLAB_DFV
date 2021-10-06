function [Ie] = ecualizah( I )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    [M,N,D]=size(I);
    
    if D==1

        Ie=zeros(M,N); %definir imagen ecualizada
        [H,HA] = histogramas(I,'si');
        
        for x=1:M
            for y=1:N
                Ie(x,y)=HA(I(x,y)+1);
            end
        end
        
        Ie=uint8(Ie);
    else
        errordlg('Error de Formato Imagen', 'I contiene ás de un plano imagen');
    end
    


end

