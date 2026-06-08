function M = calcular_peso(x_phys)
%CALCULAR_PESO  Masa total del larguero (cálculo analítico).
%c
%  Replica exactamente la lógica de corrección geométrica de ANSYS.
%  x_phys : [N x 8] — [b_upp, t_upp, b_low, t_low, h, t_web, d_hole, s]

L_spar = 8;       % m
rho    = 2810;    % kg/m³

b_upp  = x_phys(:,1);
t_upp  = x_phys(:,2);
b_low  = x_phys(:,3);
t_low  = x_phys(:,4);
h      = x_phys(:,5);
t_web  = x_phys(:,6);
d_hole = x_phys(:,7);
s      = x_phys(:,8);

%% ── Correcciones geométricas (idénticas a ANSYS) ─────────────────────
%ANSYS CALCULA EL PESO MEDIANTE LOS ELEMENTOS, EN CASO DE INESTABILIDADES
%NUMÉRICAS PODRÍA DARSE UN RESULTADO DISTINTO AL VALOR ANALÍTICO
d_hole = min(d_hole, h - 0.05);          % d_hole <= h - 0.05
s      = max(s,      1.1 .* d_hole);     % s >= 1.1 * d_hole
ratio_geom = d_hole ./ h;
if any(ratio_geom >= 0.6)
    warning('calcular_peso: %d punto(s) con d_hole/h >= 0.6. Error analitico puede superar 20%%.', ...
            sum(ratio_geom >= 0.6));
end

%% ── Cordones ─────────────────────────────────────────────────────────
V_upp = b_upp .* t_upp .* L_spar;
V_low = b_low .* t_low .* L_spar;

%% ── Alma ─────────────────────────────────────────────────────────────
edge_margin = 2.5 .* d_hole;
L_eff       = L_spar - edge_margin - d_hole;
n_holes     = round(L_eff ./ s);
A_agujeros  = n_holes .* pi .* (d_hole.^2) / 4;
V_web       = (h .* L_spar - A_agujeros) .* t_web;

%% ── Masa total ───────────────────────────────────────────────────────
M = (V_upp + V_low + V_web) .* rho;

end