clear
close all;
clc
lb=[3 4 3 4 1 4 0.15 0.4];
ub=[9 10 9 10 9 10 0.65 2.5];
opts = optimoptions(@ga, ...
    'Display', 'iter', ...                 % Te muestra en la consola de MATLAB el progreso paso a paso
    'PopulationSize', 30, ...              % Número de largueros diferentes que prueba por cada "generación"
    'MaxGenerations', 100, ...               % Límite máximo de generaciones 
    'MaxStallGenerations', 15, ...
    'OutputFcn', @GuardarProgreso,...
    'InitialPopulationMatrix', ub); 
rng(0, 'twister');
tic
[xbestDisc, fbestDisc, exitflagDisc] = ga(@PesoLargueroDiscreto, ...
    8, [], [], [], [], lb, ub, @RestriccionesDiscretas, 1:6, opts);
xbestDisc = VariablesDiscretas(xbestDisc);
display(xbestDisc);
disp('Las dimensiones del larguero para optimizar el peso son');
disp(xbestDisc)
tiempo_simulacion=toc;
disp(['Esta evaluación ha tardado exactamente ', num2str(tiempo_simulacion), ' segundos.']);
