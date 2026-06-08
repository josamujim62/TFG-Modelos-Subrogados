clear
% load db_datos200LHS
% load db_datos500LHS
load db_datos1000LHS

%% ── Solo las 3 salidas FEM ───────────────────────────────────────────
Y = Y(:, 1:3);   % Tensión, Flecha, Lambda — el Peso es analítico

%% ── Transformación log + normalización min-max ───────────────────────
dRE_log = log(dRE);
Y_log   = log(Y);

rangos.X_log_min = min(dRE_log);
rangos.X_log_max = max(dRE_log);
rangos.Y_log_min = min(Y_log);
rangos.Y_log_max = max(Y_log);

dRE_norm = (dRE_log - rangos.X_log_min) ./ (rangos.X_log_max - rangos.X_log_min);
Y_norm   = (Y_log   - rangos.Y_log_min) ./ (rangos.Y_log_max - rangos.Y_log_min);

%% ── Configuración Kriging ────────────────────────────────────────────
opts = Kriging.getDefaultOptions();
opts.hpBounds    = [-3*ones(1,8); 2*ones(1,8)];
opts.nugget=1e-6;
opts.hpOptimizer = SQPLabOptimizer(8, 1);

%% ── Entrenamiento ────────────────────────────────────────────────────
mis_modelos = cell(1, 3);
cvpe_raw    = zeros(1, 3);
tic
    fprintf('  Entrenando modelo %d/3...', 1);
    mis_modelos{1} = Kriging(opts, zeros(1,8), 'regpoly1', @corrmatern32);
    mis_modelos{1} = mis_modelos{1}.fit(dRE_norm, Y_norm(:,1));
    cvpe_raw(1)    = mis_modelos{1}.cvpe();
    fprintf(' %.1f s\n', toc);

for i = 2:3
    tic
    fprintf('  Entrenando modelo %d/3...', i);
    mis_modelos{i} = Kriging(opts, zeros(1,8), 'regpoly1', @corrmatern52);
    mis_modelos{i} = mis_modelos{i}.fit(dRE_norm, Y_norm(:,i));
    cvpe_raw(i)    = mis_modelos{i}.cvpe();
    fprintf(' %.1f s\n', toc);
end

%% ── Errores CVPE ─────────────────────────────────────────────────────
RMSE_lognorm = sqrt(cvpe_raw);
RMSE_log     = RMSE_lognorm .* (rangos.Y_log_max - rangos.Y_log_min);
CVPE_pct     = (exp(RMSE_log) - 1) * 100;

errores.RMSE_lognorm = RMSE_lognorm;
errores.RMSE_log     = RMSE_log;
errores.CVPE_pct     = CVPE_pct;

%% ── Resumen ──────────────────────────────────────────────────────────
nombres = {'Tensión', 'Flecha', 'Lambda'};
fprintf('\n%-10s  %14s  %10s\n', 'Salida', 'RMSE_lognorm', 'CVPE (%)');
for i = 1:3
    fprintf('%-10s  %14.6f  %9.2f%%\n', nombres{i}, RMSE_lognorm(i), CVPE_pct(i));
end

%% ── Guardar ──────────────────────────────────────────────────────────
% save ModeloKriging200puntos.mat mis_modelos errores CVPE_pct CVPE_real X_log_min X_log_max Y_log_min Y_log_max
% save ModeloKriging500puntos.mat mis_modelos errores CVPE_pct CVPE_real X_log_min X_log_max Y_log_min Y_log_max
save ModeloKriging1000puntos.mat mis_modelos errores CVPE_pct CVPE_real X_log_min X_log_max Y_log_min Y_log_max