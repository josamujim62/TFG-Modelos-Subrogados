% load ModeloKriging200puntos.mat
% load ModeloKriging500puntos.mat
load ModeloKriging1000puntos.mat
load pruebagrafica.mat   % contiene dRE (10x8) e Y (10x3)
X_log_min=rangos.X_log_min;
X_log_max=rangos.X_log_max;
Y_log_min=rangos.Y_log_min;
Y_log_max=rangos.Y_log_max;

%% ── Predicción sobre puntos de prueba ────────────────────────────────
N_test = size(dRE, 1);
yhat_norm = zeros(N_test, 3);
S2_norm   = zeros(N_test, 3);

for i = 1:3
    [yhat_norm(:,i), S2_norm(:,i)] = mis_modelos{i}.predict(...
        (log(dRE) - X_log_min) ./ (X_log_max - X_log_min));
end

% Desnormalizar → log → real (corrección log-normal)
yhat   = zeros(N_test, 3);
S2_real = zeros(N_test, 3);
for i = 1:3
    mu_log      = yhat_norm(:,i) * (Y_log_max(i) - Y_log_min(i)) + Y_log_min(i);
    s2_log      = S2_norm(:,i)   * (Y_log_max(i) - Y_log_min(i))^2;
    yhat(:,i)   = exp(mu_log + 0.5*s2_log);
    S2_real(:,i) = exp(2*mu_log + s2_log) .* (exp(s2_log) - 1);
end

%% ── Comparación Kriging vs ANSYS ─────────────────────────────────────
nombres = {'$\sigma_{eq}$', '$\delta$', '$\lambda$'};
figure('Name', 'Comparación Kriging vs ANSYS');
for i = 1:3
    subplot(1, 3, i)
    lims = [min([Y(:,i); yhat(:,i)]), max([Y(:,i); yhat(:,i)])];
    line(lims, lims, 'Color', 'k', 'LineStyle', '--', 'LineWidth', 1.5);
    hold on
    scatter(Y(:,i), yhat(:,i), 80, 'filled', 'MarkerFaceColor', '#0072BD');
    grid on; axis square;
    xlabel('Real (ANSYS)');
    ylabel('Predicho (Kriging)');
    title(nombres{i}, 'Interpreter', 'latex');
end

%% ── Coeficientes de determinación R² ────────────────────────────────
fprintf('\n%-12s  %8s\n', 'Salida', 'R²');
R2 = zeros(1, 3);
for i = 1:3
    SSres  = sum((Y(:,i) - yhat(:,i)).^2);
    SStot  = sum((Y(:,i) - mean(Y(:,i))).^2);
    R2(i)  = 1 - SSres/SStot;
    fprintf('%-12s  %8.4f\n', nombres{i}, R2(i));
end

%% ── Incertidumbre (varianza real) ────────────────────────────────────
figure('Name', 'Análisis de Incertidumbre');
for i = 1:3
    subplot(3, 1, i)
    bar(S2_real(:,i), 'FaceColor', [0.2 0.6 0.8])
    grid on;
    ylabel('Varianza s²');
    title(['Incertidumbre en ', nombres{i}], 'Interpreter', 'latex');
    xlabel('Índice del punto de prueba');
end

%% ── Error relativo ───────────────────────────────────────────────────
error_rel = (Y(:,1:3) - yhat) ./ Y(:,1:3) * 100;   % [N_test x 3] en %

fprintf('\n%-12s  %10s  %10s\n', 'Salida', 'ME (%)', 'MAE (%)');
for i = 1:3
    fprintf('%-12s  %10.4f  %10.4f\n', nombres{i}, ...
            mean(error_rel(:,i)), mean(abs(error_rel(:,i))));
end