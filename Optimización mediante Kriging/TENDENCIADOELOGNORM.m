close all
% load db_datos200LHS.mat
% load db_datos500LHS.mat
load db_datos1000LHS.mat

%% ── Transformación log-norm de entradas y salidas ────────────────────
dRE_log = log(dRE);
Y_log   = log(Y(:,1:4));

X_log_min = min(dRE_log);   X_log_max = max(dRE_log);
Y_log_min = min(Y_log);     Y_log_max = max(Y_log);

X      = (dRE_log - X_log_min) ./ (X_log_max - X_log_min);
Y_norm = (Y_log   - Y_log_min) ./ (Y_log_max - Y_log_min);

%% ── Nombres ──────────────────────────────────────────────────────────
nombres_X_hm = {'b_{upp}', 't_{upp}', 'b_{low}', 't_{low}', 'h', 't_{web}', 'd_{hole}', 's'};
nombres_Y_hm = {'\sigma_{eq}', '\delta', '\lambda', 'peso'};

nombres_X = {'$b_{upp}$', '$t_{upp}$', '$b_{low}$', '$t_{low}$', '$h$', '$t_{web}$', '$d_{hole}$', '$s$'};
nombres_Y = {'$\sigma_{eq}$', '$\delta$', '$\lambda$', '$peso$'};

%% ── Correlación de Spearman ──────────────────────────────────────────
R = corr(X, Y_norm, 'type', 'Spearman');

%% ── Heatmap ──────────────────────────────────────────────────────────
figure
h = heatmap(nombres_Y_hm, nombres_X_hm, R);
h.Title    = 'Impacto de Entradas sobre cada Salida (espacio log-norm)';
h.Colormap = sky;

%% ── Scatter plots ────────────────────────────────────────────────────
num_entradas = size(X, 2);
num_salidas  = size(Y_norm, 2);

figure
t = tiledlayout(num_salidas, num_entradas, 'TileSpacing', 'compact');

for i = 1:num_salidas
    for j = 1:num_entradas
        nexttile
        scatter(X(:,j), Y_norm(:,i), 20, 'filled', 'MarkerFaceAlpha', 0.5)
        hold on
        lsline
        grid on
        if j == 1
            ylabel(nombres_Y{i}, 'Interpreter', 'latex')
        end
        if i == num_salidas
            xlabel(nombres_X{j}, 'Interpreter', 'latex')
        end
    end
end

title(t, 'Tendencias Entrada-Salida (espacio log-norm)', 'Interpreter', 'latex')