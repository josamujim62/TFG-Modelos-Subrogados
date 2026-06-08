function [state, options, optchanged] = GuardarProgreso(options, state, flag)
    optchanged = false;
    % Solo actuamos al final de cada generación
    if strcmp(flag, 'iter')
        % Buscamos quién es el mejor de esta generación
        [~, idx] = min(state.Score);
        mejor_x_actual = state.Population(idx, :);
        mejor_peso_actual = state.Score(idx);
        
        % GUARDADO AUTOMÁTICO EN DISCO
        % Guardamos el vector x y el peso en un archivo temporal
        save('BACKUP_OPTIMIZACION_v2.mat', 'mejor_x_actual', 'mejor_peso_actual');
        
        % Mensaje rápido en consola para tu tranquilidad
        fprintf('Generación %d guardada. Mejor peso: %.3f kg\n', state.Generation, mejor_peso_actual);
    end
end