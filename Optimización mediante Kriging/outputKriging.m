function [state, options, optchanged] = outputKriging(options, state, flag, mis_modelos, rangos)
%OUTPUTKRIGING  OutputFcn para GA: muestra predicciones Kriging del mejor individuo.
%
%  Se llama automáticamente en cada generación. Imprime tensión, flecha
%  y lambda predichos para el mejor individuo de la generación actual.

optchanged = false;

switch flag
    case 'init'
        fprintf('\n%-6s  %-10s  %-12s  %-10s  %-10s\n', ...
            'Gen', 'Peso(kg)', 'Tensión(MPa)', 'Flecha(m)', 'Lambda');
        fprintf('%s\n', repmat('-', 1, 56));

    case 'iter'
        % Mejor individuo de la generación actual
        [~, idx] = min(state.Score);
        x_best   = state.Population(idx, :);

        % Convertir a valores físicos y predecir
        x_phys      = VariablesDiscretas(x_best);
        peso        = calcular_peso(x_phys);
        [y_pred, ~] = PrediccionKriging(x_phys, mis_modelos, rangos);

        tension = y_pred(1) / 1e6;   % Pa → MPa
        flecha  = y_pred(2);          % m
        lambda  = y_pred(3);

        % Indicadores de restricción (OK / XX)
        L_spar = 8;
        ok_t = tension <= 455;          
        ok_f = flecha  <= L_spar/25;
        ok_l = lambda  >= 1.50;          
        flag_t = selectflag(ok_t);
        flag_f = selectflag(ok_f);
        flag_l = selectflag(ok_l);

        fprintf('%-6d  %-10.1f  %6.2f %s     %6.4f %s  %5.3f %s\n', ...
            state.Generation, peso, tension, flag_t, flecha, flag_f, lambda, flag_l);

    case 'done'
        fprintf('%s\n', repmat('-', 1, 56));
        fprintf('GA finalizado.\n\n');
end
end

function s = selectflag(ok)
    if ok
        s = 'OK';
    else
        s = 'XX';
    end
end
