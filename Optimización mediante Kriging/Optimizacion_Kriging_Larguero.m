clear; close all; clc;

  load('ModeloKriging_Infill_EI_500_v2.mat', 'mis_modelos', 'rangos');
lb=[3 1 3 1 1 1 0.15 0.4];
ub = [9, 10, 9, 10, 9, 10, 0.65, 2.50];
semilla_optima=[5 7 9 8 9 7 0.6496 0.7504];
semilla_optima_200=[5 8 9 9 8 7 0.6489 0.7637];
opts = optimoptions('ga', ...
    'Display',                'iter',   ...
    'PopulationSize',         100,       ...
    'MaxGenerations',         1000,      ...
    'MaxStallGenerations',    50,        ...
    'OutputFcn',              @(opts,state,flag) outputKriging(opts,state,flag,mis_modelos,rangos), ...
    'InitialPopulationMatrix', semilla_optima_200, ... 
    'PlotFcn',                {@gaplotscores, @gaplotbestf}); 
fun_obj  = @(x) calcular_peso_discreto(x);
fun_rest = @(x) RestriccionesDiscretas_Kriging(x, mis_modelos, rangos);

rng(0, 'twister');
tic
[xbest, fbestDisc, exitflag] = ga( ...
    fun_obj, 8,         ...
    [], [], [], [],     ...
    lb, ub,             ...
    fun_rest,           ...
    1:6,                ...
    opts);
tiempo_GA = toc;

xbest_phys = VariablesDiscretas(xbest);
[y_pred, ~] = PrediccionKriging(xbest_phys, mis_modelos, rangos);
L_spar = 8;

fprintf('\n========================================\n');
fprintf('  RESULTADO OPTIMIZACIÓN GA-Kriging\n');
fprintf('========================================\n');
fprintf('  Exitflag : %d\n', exitflag);
fprintf('  Tiempo   : %.1f s\n\n', tiempo_GA);
nombres = {'b_upp (m)', 't_upp (m)', 'b_low (m)', 't_low (m)', ...
           'h (m)',     't_web (m)', 'd_hole (m)', 's (m)'};
for k = 1:8
    fprintf('    %-14s = %.5f\n', nombres{k}, xbest_phys(k));
end
fprintf('\n  Peso mínimo: %.3f kg\n', fbestDisc);
fprintf('\n  Predicción Kriging en óptimo:\n');
fprintf('    Tensión        : %8.2f MPa  (límite 455 MPa)\n', y_pred(1)/1e6);
fprintf('    Flecha         : %8.4f m    (límite %.4f m = L/25)\n',                  y_pred(2), L_spar/25);
fprintf('    Factor seguridad: %7.3f     (límite 1.50)\n',        y_pred(3));
fprintf('========================================\n\n');
