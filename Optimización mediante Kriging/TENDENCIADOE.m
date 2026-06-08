close all
% load db_datos200LHS.mat
% load db_datos500LHS.mat
load db_datos1000LHS.mat

% Nombres para heatmap (sin LaTeX)
nombres_X_hm = {'b_{upp}', 't_{upp}', 'b_{low}', 't_{low}', 'h', 't_{web}', 'd_{hole}', 's'};
nombres_Y_hm = {'\sigma_{eq}', '\delta', '\lambda', 'peso'};

% Nombres para scatter (con LaTeX)
nombres_X = {'$b_{upp}$', '$t_{upp}$', '$b_{low}$', '$t_{low}$', '$h$', '$t_{web}$', '$d_{hole}$', '$s$'};
nombres_Y = {'$\sigma_{eq}$', '$\delta$', '$\lambda$', '$peso$'};

% Calculamos la correlación solo entre Entradas y Salidas
R = corr(X, Y_norm, 'type', 'Spearman');

% Visualización heatmap
figure
h = heatmap(nombres_Y_hm, nombres_X_hm, R);
h.Title = 'Impacto de Entradas sobre cada Salida Independiente';
h.Colormap = sky;

% Cuadrícula de scatter plots
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

title(t, 'Análisis de Tendencias por cada Par Entrada-Salida', ...
    'Interpreter', 'latex')