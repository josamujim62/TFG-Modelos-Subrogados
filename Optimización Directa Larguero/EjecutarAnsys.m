function res = EjecutarAnsys(x)
    % Usamos un diccionario para guardar TODOS los diseños evaluados
    persistent MapaCache
    if isempty(MapaCache)
        MapaCache = containers.Map('KeyType', 'char', 'ValueType', 'any');
    end

    % Convertimos el vector 'x' en un texto para usarlo como "llave" del diccionario
    x_key = mat2str(x); 

    % 1. Si el diseño ya se evaluó antes, sacamos el resultado del diccionario y NO abrimos ANSYS
    if isKey(MapaCache, x_key)
        res = MapaCache(x_key);
        return;
    end
    % 2. Si llegamos aquí, es un diseño nuevo. Preparamos ANSYS.
    if exist('Resultados_Out.txt', 'file'); delete('Resultados_Out.txt'); end
    if exist('LARGUERO.lock', 'file'); delete('LARGUERO.lock'); end 

    fileID = fopen('VARINPUT.txt','w');
    fprintf(fileID, '%.8f\n', x(:)); 
    fclose(fileID);

    % Ejecución bloqueante (MATLAB espera automáticamente a que termine)
    dos('"C:\Program Files\ANSYS Inc\ANSYS Student\v252\ansys\bin\winx64\ansys252.exe" -b -dir "C:\Users\josam\Documents\GIA\TFG\3.LARGUERO FEM" -i "LARGUERO.txt" -o "Resultadosoptim.out"');
    
    % Un pequeño respiro de seguridad para que Windows termine de escribir el .txt
    pause(0.5); 

    % Valores de castigo iniciales por si ANSYS falla o no converge
    res = [1e12 1e12 0.001 1e6]; 

    % 3. Lectura segura del archivo de resultados
    if exist('Resultados_Out.txt', 'file')
        try
            lectura = readmatrix('Resultados_Out.txt');
            lectura = lectura(~isnan(lectura)); 
            if length(lectura) >= 4
                res = lectura(1:4);
            end
        catch
            res = [1e12 1e12 0.001 1e6];
        end
    end

   % 4. Guardamos el resultado en el diccionario para cuando MATLAB pida las restricciones
    MapaCache(x_key) = res;
end