function J = criterio_varianza(x_norm, mis_modelos, rangos, dRE_norm)
%CRITERIO_VARIANZA  Máxima varianza global con penalización clustering.
%
%  Busca el punto con mayor incertidumbre total en los 3 surrogates,
%  evitando proponer puntos demasiado cercanos a los ya existentes.
%  No persigue el mínimo: reduce el error global del surrogate.
%
%  ENTRADAS
%    x_norm      : punto candidato en [0,1]^8          (1 x 8)
%    mis_modelos : cell(1,3) — Tensión, Flecha, Lambda
%    rangos      : struct de KrigingAvanzado
%    dRE_norm    : puntos de entrenamiento en [0,1]^8  (N x 8)
%
%  SALIDA
%    J : negativo de la varianza total ponderada (GA minimiza)

%% ── Restricción geométrica en espacio físico ─────────────────────────
x_log  = x_norm .* (rangos.X_log_max - rangos.X_log_min) + rangos.X_log_min;
x_phys = exp(x_log);

if x_phys(7) / x_phys(5) >= 0.6
    J = 0;
    return
end

%% ── Varianza total ponderada en espacio log-norm ─────────────────────
% Cada salida tiene distinto rango log → normalizamos s2 por el rango
% para que las 3 contribuyan de forma comparable
s2_total = 0;
for i = 1:3
    [~, s2] = mis_modelos{i}.predict(x_norm);
    % Escalar por el rango logarítmico de cada salida
    rango_i  = (rangos.Y_log_max(i) - rangos.Y_log_min(i))^2;
    s2_total = s2_total + max(s2, 0) * rango_i;
end

%% ── Penalización clustering ──────────────────────────────────────────
N      = size(dRE_norm, 1);
dmin   = min(vecnorm(dRE_norm - x_norm, 2, 2));
umbral = 0.5 * N^(-1/8);

if dmin < umbral
    J = 0;
    return
end

%% ── Criterio final ───────────────────────────────────────────────────
J = -(sqrt(s2_total) * dmin);

end
