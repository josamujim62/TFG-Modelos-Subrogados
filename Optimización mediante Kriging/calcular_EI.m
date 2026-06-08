function EIC = calcular_EI(x_norm, mis_modelos, rangos, f_mejor_peso)
%CALCULAR_EI  EI restringido: EI_peso × PoF_tension × PoF_flecha × PoF_lambda
%
%  El Peso se calcula analíticamente (no tiene surrogate).
%  Las restricciones se evalúan con los surrogates de Tensión, Flecha y Lambda.
%
%  Restricciones físicas:
%    Tensión < 455e6  Pa
%    Flecha  < 0.32   m
%    Lambda  > 1.5
%
%  ENTRADAS
%    x_norm       : punto candidato en [0,1]^8    (1 x 8)
%    mis_modelos  : cell(1,3) — Tensión, Flecha, Lambda
%    rangos       : struct de KrigingAvanzado
%    f_mejor_peso : mejor Peso viable actual en espacio físico (escalar, kg)

%% ── Límites de restricciones ─────────────────────────────────────────
margen=0.15;
lim_tension = 455e6*(1-margen);   % Pa
lim_flecha  = 8/25;    % m
lim_lambda  = 1.5;

%% ── Desnormalizar x para calcular peso y restricción geométrica ──────
x_log  = x_norm .* (rangos.X_log_max - rangos.X_log_min) + rangos.X_log_min;
x_phys = exp(x_log);

%% ── Restricción geométrica: d_hole/h < 0.6 (en espacio físico) ───────
if x_phys(7) / x_phys(5) >= 0.6
    EIC = 0;
    return
end

%% ── EI del Peso (analítico, determinista) ────────────────────────────
peso_actual = calcular_peso(x_phys);
EI_peso     = max(f_mejor_peso - peso_actual, 0) / f_mejor_peso;

%% ── PoF Tensión: P(σ < 386.75e6) ───────────────────────────────────────
lim_t_norm  = (log(lim_tension) - rangos.Y_log_min(1)) / ...
              (rangos.Y_log_max(1) - rangos.Y_log_min(1));
[mu1, s2_1] = mis_modelos{1}.predict(x_norm);
s1          = sqrt(max(s2_1, 0));
PoF_tension = normcdf((lim_t_norm - mu1) / max(s1, 1e-10));

%% ── PoF Flecha: P(δ < 0.32) ─────────────────────────────────────────
lim_f_norm  = (log(lim_flecha) - rangos.Y_log_min(2)) / ...
              (rangos.Y_log_max(2) - rangos.Y_log_min(2));
[mu2, s2_2] = mis_modelos{2}.predict(x_norm);
s2          = sqrt(max(s2_2, 0));
PoF_flecha  = normcdf((lim_f_norm - mu2) / max(s2, 1e-10));

%% ── PoF Lambda: P(Λ > 1.5) ──────────────────────────────────────────
lim_l_norm  = (log(lim_lambda) - rangos.Y_log_min(3)) / ...
              (rangos.Y_log_max(3) - rangos.Y_log_min(3));
[mu3, s2_3] = mis_modelos{3}.predict(x_norm);
s3          = sqrt(max(s2_3, 0));
PoF_lambda  = 1 - normcdf((lim_l_norm - mu3) / max(s3, 1e-10));

%% ── EIC final ────────────────────────────────────────────────────────
EIC = -(EI_peso * PoF_tension * PoF_flecha * PoF_lambda);

end
