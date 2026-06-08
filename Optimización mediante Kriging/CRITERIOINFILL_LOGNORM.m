%% =========================================================
%% CRITERIOINFILL_LOGNORM.m
%%
%% Muestreo adaptativo (EGO) con criterio seleccionable:
%%   'EI'       : EI × PoF — refina cerca del mínimo de Peso
%%   'VARIANZA' : Máxima varianza — reduce error global del surrogate
%%
%% Objetivo : minimizar Peso (analítico)
%% Restricciones (surrogates Kriging):
%%   Tensión < 455e6 Pa  |  Flecha < 0.32 m  |  Lambda > 1.5
%%
%% Salidas FEM:  1=Tensión  2=Flecha  3=Lambda
%% =========================================================

clear; clc; close all

%% ── Cargar DOE inicial ───────────────────────────────────────────────
load db_datos200LHS.mat
Y = Y(:,1:3);

%% ── Selección de criterio ────────────────────────────────────────────
%  'EI'       → busca el mínimo de Peso en zona viable
%  'VARIANZA' → reduce el error global del surrogate (DEMOSTRADO
%  INEFICIENTE)
CRITERIO = 'EI';
%CRITERIO= 'VARIANZA';

%% ── Límites físicos del espacio de diseño ────────────────────────────
%         b_upp    t_upp    b_low    t_low    h       t_web   d_hole   s
lb = [0.2  0.00483  0.2  0.00483  0.4  0.00483  0.15  0.4];
ub = [0.5  0.0508   0.5  0.0508   1.2  0.0508   0.65  2.5];

%% ── Restricciones físicas ────────────────────────────────────────────
lim_tension = 455e6;
lim_flecha  = 8/25;
lim_lambda  = 1.5;

%% ── Peso analítico del DOE inicial ───────────────────────────────────
Peso_DOE = calcular_peso(dRE);

%% ── Parámetros del bucle EGO ─────────────────────────────────────────
max_iter      = 50;
mejora_minima = 0.01;
paciencia     = 10;
tol_CVPE= 4.0;
% Nuevas variables para el criterio de parada por EIC consecutivo
tol_EI        = 0.01;  
paciencia_EI  = 10;    
contador_EI   = 0;     % Contador de iteraciones seguidas con baja mejora

%% ── Contenedores de histórico ────────────────────────────────────────
historial_CVPE   = zeros(max_iter, 3);
historial_crit   = zeros(max_iter, 1);   % valor del criterio elegido
historial_xnew   = zeros(max_iter, 8);
historial_ynew   = zeros(max_iter, 3);
historial_peso   = zeros(max_iter, 1);
historial_viable = false(max_iter, 1);

contador_estancamiento = 0;

%% ── Opciones GA ──────────────────────────────────────────────────────
optsGA = optimoptions(@ga, ...
    'Display',           'off', ...
    'PopulationSize',    80,    ...
    'MaxGenerations',    200,   ...
    'FunctionTolerance', 1e-8,  ...
    'UseParallel',       true);

fprintf('Criterio seleccionado: %s\n', CRITERIO);
tic

%% =========================================================
%% BUCLE PRINCIPAL
%% =========================================================
for iter = 1:max_iter

    fprintf('\n========================================\n');
    fprintf('ITERACION %d / %d  (N = %d puntos)\n', iter, max_iter, size(dRE,1));
    fprintf('========================================\n');

    %% ── 1. Entrenar Kriging ──────────────────────────────────────────
    [mis_modelos, errores, rangos] = KrigingAvanzado(dRE, Y);

    CVPE = errores.CVPE_pct;
    historial_CVPE(iter, :) = CVPE;
    fprintf('CVPE:  Tension=%.2f%%  Flecha=%.2f%%  Lambda=%.2f%%\n', ...
            CVPE(1), CVPE(2), CVPE(3));

    %% ── 2. Criterio de parada: CVPE global ───────────────────────────
    if max(CVPE) < tol_CVPE
        fprintf('\nCVPE objetivo alcanzado (max=%.2f%% < %.1f%%)\n', max(CVPE), tol_CVPE);
        break
    end

    %% ── 3. Criterio de parada: estancamiento ─────────────────────────(EN  DESUSO AHORA MISMO)
    % cvpe_actual_max = max(CVPE);
    % 
    % if iter == 1
    %     mejor_cvpe_historico = cvpe_actual_max; % Registrar el primer valor como récord inicial
    % else
    %     % Calcular la mejora respecto al mejor modelo histórico real
    %     mejora = (mejor_cvpe_historico - cvpe_actual_max) / mejor_cvpe_historico;
    %     fprintf('Mejora rel. respecto al récord histórico: %.4f\n', mejora);
    % 
    %     if mejora >= mejora_minima
    %         mejor_cvpe_historico = cvpe_actual_max; % ¡Nuevo récord establecido!
    %         contador_estancamiento = 0;            % Se reinicia: no es consecutivo
    %         fprintf('¡Nueva mejor aproximación global! Contador reiniciado.\n');
    %     else
    %         contador_estancamiento = contador_estancamiento + 1; % No supera el récord + el umbral
    %         fprintf('Estancamiento consecutivo: %d / %d\n', contador_estancamiento, paciencia);
    %     end
    % 
    %     if contador_estancamiento >= paciencia
    %         fprintf('\nAlgoritmo estancado (10 iteraciones seguidas sin superar el récord). Deteniendo.\n');
    %         break
    %     end
    % end

    %% ── 4. Viabilidad y mejor Peso ───────────────────────────────────
    viable = (Y(:,1) < lim_tension)        & ...
             (Y(:,2) < lim_flecha)          & ...
             (Y(:,3) > lim_lambda)          & ...
             (dRE(:,7) ./ dRE(:,5) < 0.6);

    n_viable = sum(viable);
    fprintf('Puntos viables en DOE: %d / %d\n', n_viable, size(Y,1));

    if n_viable == 0
        warning('Sin puntos viables. Usando mínimo global de Peso.');
        f_mejor_peso = min(Peso_DOE);
    else
        f_mejor_peso = min(Peso_DOE(viable));
        fprintf('Mejor Peso viable: %.4f kg\n', f_mejor_peso);
    end

    %% ── 5. GA: criterio seleccionado ─────────────────────────────────
    dRE_norm = (log(dRE) - rangos.X_log_min) ./ (rangos.X_log_max - rangos.X_log_min);

    switch CRITERIO
        case 'EI'
            criterio = @(x) calcular_EI(x, mis_modelos, rangos, f_mejor_peso);
            fprintf('Buscando nuevo punto (GA + EI x PoF)...\n');
        case 'VARIANZA'
            criterio = @(x) criterio_varianza(x, mis_modelos, rangos, dRE_norm);
            fprintf('Buscando nuevo punto (GA + Maxima Varianza)...\n');
        otherwise
            error('CRITERIO debe ser ''EI'' o ''VARIANZA''');
    end

    [x_new_norm, crit_opt] = ga(criterio, 8, [], [], [], [], ...
                                 zeros(1,8), ones(1,8), [], optsGA);
    valor_criterio=-crit_opt;
    historial_crit(iter) = valor_criterio;
    fprintf('Criterio optimo: %.6e\n', -crit_opt);
    %% ── 5b. NUEVO CRITERIO DE PARADA: EIC < 0.01 consecutivas ────────
    if strcmp(CRITERIO, 'EI')
        if valor_criterio < tol_EI
            contador_EI = contador_EI + 1;
            fprintf('-> EIC por debajo del umbral (< %.2f): [%d / %d] seguidas.\n', tol_EI, contador_EI, paciencia_EI);
        else
            contador_EI = 0; % ¡Reset estricto! Si vuelve a subir de 0.01, el contador vuelve a cero.
        end

        if contador_EI >= paciencia_EI
            fprintf('\n[PARADA] La Mejora Esperada (EIC) ha sido menor que %.2f durante %d iteraciones seguidas.\n', tol_EI, paciencia_EI);
            break
        end
    end

    %% ── 6. Desnormalizar a espacio físico ────────────────────────────
    x_new_log  = x_new_norm .* (rangos.X_log_max - rangos.X_log_min) + rangos.X_log_min;
    x_new_phys = exp(x_new_log);
    x_new_phys = max(lb, min(ub, x_new_phys));
    peso_nuevo = calcular_peso(x_new_phys);

    fprintf('Nuevo punto fisico:\n');
    fprintf('  b_upp=%.4f  t_upp=%.5f  b_low=%.4f  t_low=%.5f\n', ...
            x_new_phys(1), x_new_phys(2), x_new_phys(3), x_new_phys(4));
    fprintf('  h=%.4f  t_web=%.5f  d_hole=%.4f  s=%.4f\n', ...
            x_new_phys(5), x_new_phys(6), x_new_phys(7), x_new_phys(8));
    fprintf('  Peso analitico: %.4f kg\n', peso_nuevo);

    %% ── 7. Predicción surrogate antes de ANSYS ───────────────────────
    [y_pred, ~] = predecir_lognorm(x_new_phys, mis_modelos, rangos);
    fprintf('Prediccion surrogate:\n');
    fprintf('  Tension=%.2f (lim=%.0f)  Flecha=%.4f (lim=%.4f)  Lambda=%.4f (lim=%.2f)\n', ...
            y_pred(1), lim_tension, y_pred(2), lim_flecha, y_pred(3), lim_lambda);

    %% ── 8. Exportar variables para ANSYS ─────────────────────────────
    dlmwrite('VARINPUTSUB.txt', x_new_phys', ...
             'delimiter', '\t', 'precision', '%4.5f');

    %% ── 9. Ejecutar ANSYS ────────────────────────────────────────────
    fprintf('Ejecutando ANSYS...\n');
    dos(['"C:\Program Files\ANSYS Inc\ANSYS Student\v252\ansys\bin\winx64\ansys252.exe"' ...
         ' -b' ...
         ' -dir "C:\Users\josam\Documents\GIA\TFG\3.LARGUERO FEM\1. ENTRENAMIENTO Y CREACION SURROGADO"' ...
         ' -i "LARGUEROSUB.txt"' ...
         ' -o "ResultadosoptimSUB.out"']);

    %% ── 10. Leer resultados ANSYS ────────────────────────────────────
    Resultados = load('Resultados_Out_SUB.txt');
    y_new = Resultados(~isnan(Resultados));

    if length(y_new) < 3
        warning('Resultados ANSYS invalidos en iteracion %d. Saltando.', iter);
        continue
    end

    peso_ansys = y_new(4);
    y_new      = y_new(1:3)';

    es_viable = (y_new(1) < lim_tension) && ...
                (y_new(2) < lim_flecha)  && ...
                (y_new(3) > lim_lambda);
    historial_viable(iter) = es_viable;

    fprintf('Resultados ANSYS:\n');
    fprintf('  Tension=%.2f %s  Flecha=%.4f %s  Lambda=%.4f %s\n', ...
            y_new(1), estado(y_new(1) < lim_tension), ...
            y_new(2), estado(y_new(2) < lim_flecha),  ...
            y_new(3), estado(y_new(3) > lim_lambda));
    fprintf('  Peso analitico=%.4f kg  Peso ANSYS=%.4f kg  →  %s\n', ...
            peso_nuevo, peso_ansys, ternario(es_viable, 'VIABLE ✓', 'NO VIABLE ✗'));

    %% ── 11. Error predicción vs ANSYS ────────────────────────────────
    err_rel = abs(y_new - y_pred(1:3)) ./ abs(y_new) * 100;
    fprintf('Error pred vs ANSYS:  Tension=%.2f%%  Flecha=%.2f%%  Lambda=%.2f%%\n', ...
            err_rel(1), err_rel(2), err_rel(3));

    %% ── 12. Actualizar DOE ───────────────────────────────────────────
    dRE      = [dRE;      x_new_phys];
    Y        = [Y;        y_new];
    Peso_DOE = [Peso_DOE; peso_nuevo];

    historial_xnew(iter, :) = x_new_phys;
    historial_ynew(iter, :) = y_new;
    historial_peso(iter)    = peso_nuevo;

    %% ── 13. Guardado de seguridad ────────────────────────────────────
    save('Backup_Infill.mat', 'dRE', 'Y', 'Peso_DOE', ...
         'historial_CVPE', 'historial_crit', ...
         'historial_xnew', 'historial_ynew', ...
         'historial_peso',  'historial_viable', 'iter', 'CRITERIO');

    %% ── 14. Gráficas ─────────────────────────────────────────────────
    figure(1); clf

    subplot(3,1,1)
    plot(historial_CVPE(1:iter,1), 'LineWidth', 2); hold on
    plot(historial_CVPE(1:iter,2), 'LineWidth', 2)
    plot(historial_CVPE(1:iter,3), 'LineWidth', 2)
    yline(tol_CVPE, 'k--', 'LineWidth', 1.5)
    xlabel('Iteración'); ylabel('CVPE (%)');
    title(['Error de validación cruzada — criterio: ' CRITERIO]);
    legend('Tensión','Flecha','Lambda','Objetivo','Location','best');
    grid on

    subplot(3,1,2)
    semilogy(abs(historial_crit(1:iter)), 'r-o', 'LineWidth', 2, 'MarkerSize', 5)
    xlabel('Iteración'); ylabel('Criterio (log)');
    title(CRITERIO);
    grid on

    subplot(3,1,3)
    viable_run = (Y(:,1) < lim_tension) & (Y(:,2) < lim_flecha) & (Y(:,3) > lim_lambda);
    plot(cumsum(viable_run), 'b-o', 'LineWidth', 2, 'MarkerSize', 4)
    xlabel('Puntos en DOE'); ylabel('Viables acumulados');
    title('Puntos viables acumulados en DOE');
    grid on

    drawnow

end

%% ── Resumen final ────────────────────────────────────────────────────
tiempo_total = toc;
n_iter_real  = min(iter, max_iter);

viable_final = (Y(:,1) < lim_tension) & ...
               (Y(:,2) < lim_flecha)  & ...
               (Y(:,3) > lim_lambda);

fprintf('\n========================================\n');
fprintf('FIN DEL MUESTREO ADAPTATIVO — %s\n', CRITERIO);
fprintf('Iteraciones realizadas  : %d\n',   n_iter_real);
fprintf('Puntos totales en DOE   : %d\n',   size(dRE,1));
fprintf('Puntos viables en DOE   : %d\n',   sum(viable_final));
if any(viable_final)
    fprintf('Mejor Peso viable       : %.4f kg\n', min(Peso_DOE(viable_final)));
end
fprintf('Tiempo total            : %.4f \n', tiempo_total);
fprintf('========================================\n');

%% ── Modelo final ─────────────────────────────────────────────────────
[mis_modelos, errores, rangos] = KrigingAvanzado(dRE, Y);

save('ModeloKriging_Infill_EI_500_v2.mat', ...
     'mis_modelos', 'errores', 'rangos', ...
     'dRE', 'Y', 'Peso_DOE', 'CRITERIO', ...
     'historial_CVPE', 'historial_crit', ...
     'historial_xnew', 'historial_ynew', ...
     'historial_peso',  'historial_viable');

fprintf('Modelo final guardado en ModeloKriging_Infill_EI_500_v2.mat\n');

%% ── Funciones auxiliares ─────────────────────────────────────────────
function s = estado(condicion)
    if condicion; s = 'OK'; else; s = 'XX'; end
end

function s = ternario(condicion, a, b)
    if condicion; s = a; else; s = b; end
end
