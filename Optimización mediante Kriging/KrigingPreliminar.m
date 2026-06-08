%% =====================================================================
%% METAMODELO KRIGING PARA VIGA ALVEOLAR (CON CONVERSIÓN DE ERRORES REALES)
%% =====================================================================
clear; clc;
% load db_datos200LHS.mat
% load db_datos500LHS.mat
load db_datos1000LHS.mat

% Nombres de tus variables para que los reportes en consola sean claros
nombres_outputs = {'Tensión (Sigma_eq)', 'Flecha (Delta)', 'Pandeo (Lambda)'};

%% ── 1. PREPROCESAMIENTO: TRANSFORMACIÓN LOG + MIN-MAX ────────────────
dRE_log = log(dRE);
Y_log   = log(Y(:,1:3));

% Límites para la normalización
X_log_min = min(dRE_log);   X_log_max = max(dRE_log);
Y_log_min = min(Y_log);     Y_log_max = max(Y_log);

% Escalado en rango [0, 1]
dRE_norm = (dRE_log - X_log_min) ./ (X_log_max - X_log_min);
Y_norm   = (Y_log   - Y_log_min) ./ (Y_log_max - Y_log_min);

%% ── 2. ENTRENAMIENTO DE MODELOS Y EVALUACIÓN DE ERROR ────────────────
mis_modelos_pre           = cell(1,3);
errores_cv_pre            = zeros(1,3);
error_relativo_porcentaje = zeros(1,3);
rmse_real_aprox           = zeros(1,3);

fprintf('=== ENTRANDO EN ENTRENAMIENTO Y VALIDACIÓN CRUZADA ===\n');

for i = 1:3
    % Ajuste del metamodelo Kriging
    mis_modelos_pre{i} = oodacefit(dRE_norm, Y_norm(:,i));
    
    % Extracción del error de validación cruzada (espacio normalizado)
    errores_cv_pre(i) = mis_modelos_pre{i}.cvpe();
    
    % --- CONVERSIÓN DE ERRORES AL ESPACIO REAL (Geometría Log-Normal) ---
    % 1. Pasar el MSE del espacio normalizado al espacio logarítmico
    mse_log = errores_cv_pre(i) * (Y_log_max(i) - Y_log_min(i))^2;
    
    % 2. Error relativo real (%) -> Coeficiente de variación
    error_relativo_porcentaje(i) = sqrt(exp(mse_log) - 1) * 100; 
    
    % 3. RMSE absoluto aproximado basado en la escala media de la muestra
    rmse_real_aprox(i) = mean(Y(:,i)) * sqrt(exp(mse_log) - 1);
    
    % Reporte de precisión por consola
    fprintf('%s:\n', nombres_outputs{i});
    fprintf('  > Error Relativo Medio : %.2f%%\n', error_relativo_porcentaje(i));
    fprintf('  > RMSE Absoluto Aprox  : %.4f\n\n', rmse_real_aprox(i));
end

%% ── 3. PREDICCIÓN EN UN NUEVO PUNTO DE DISEÑO ────────────────────────
x_nuevo = [0.3 0.0254 0.45 0.0381 0.9 0.019 0.5740 0.6687];

% Normalizar el punto exactamente con los mismos parámetros de entrenamiento
x_nuevo_norm = (log(x_nuevo) - X_log_min) ./ (X_log_max - X_log_min);

y_real  = zeros(1,3);
s2_real = zeros(1,3);

fprintf('=== PREDICCIÓN PARA EL NUEVO PUNTO DE DISEÑO ===\n');

for i = 1:3
    % Predicción en el espacio transformado y normalizado
    [y_n, s2_n] = mis_modelos_pre{i}.predict(x_nuevo_norm);
    
    % Deshacer la normalización Min-Max (Regresar al espacio logarítmico)
    mu_log  = y_n  * (Y_log_max(i) - Y_log_min(i)) + Y_log_min(i);
    s2_log  = s2_n * (Y_log_max(i) - Y_log_min(i))^2;
    
    % Deshacer la transformación Logarítmica (Corrección analítica anti-sesgo)
    y_real(i)  = exp(mu_log + 0.5 * s2_log);
    s2_real(i) = exp(2 * mu_log + s2_log) * (exp(s2_log) - 1);
    
    % Reporte de predicciones
    fprintf('%s:\n', nombres_outputs{i});
    fprintf('  > Valor esperado (Medio)  : %.4f\n', y_real(i));
    fprintf('  > Varianza de la predicción: %.6f\n\n', s2_real(i));
end
% save ModeloKrigingPreliminar200.mat mis_modelos_pre rmse_real_aprox s2_real 
% save ModeloKrigingPreliminar500.mat mis_modelos_pre rmse_real_aprox s2_real 
% save ModeloKrigingPreliminar1000.mat mis_modelos_pre rmse_real_aprox s2_real 