function [y_real, s2_real, y_norm, s2_norm] = predecir_lognorm(x_phys, mis_modelos, rangos)
%PREDECIR_LOGNORM  Predicción en espacio real desde un punto físico.
%
%  [y_real, s2_real] = predecir_lognorm(x_phys, mis_modelos, rangos)
%
%  ENTRADAS
%    x_phys      : punto en espacio físico  [1 x 8]
%    mis_modelos : cell(1,4) devuelto por KrigingAvanzado
%    rangos      : struct devuelto por KrigingAvanzado
%
%  SALIDAS
%    y_real  : [1x4] predicción media en espacio real  (corrección log-normal)
%              Columnas: Tensión, Flecha, Lambda, Peso
%    s2_real : [1x4] varianza en espacio real
%    y_norm  : [1x4] predicción en espacio log-norm [0,1]  (uso interno EGO)
%    s2_norm : [1x4] varianza en espacio log-norm [0,1]    (uso interno EGO)

n_out  = length(mis_modelos);   % 4
x_norm = (log(x_phys) - rangos.X_log_min) ./ (rangos.X_log_max - rangos.X_log_min);

y_real  = zeros(1, n_out);
s2_real = zeros(1, n_out);
y_norm  = zeros(1, n_out);
s2_norm = zeros(1, n_out);

for i = 1:n_out
    [yn, s2n] = mis_modelos{i}.predict(x_norm);
    y_norm(i)  = yn;
    s2_norm(i) = s2n;

    % Desnormalizar → espacio log
    mu_log  = yn  * (rangos.Y_log_max(i) - rangos.Y_log_min(i)) + rangos.Y_log_min(i);
    s2_log  = s2n * (rangos.Y_log_max(i) - rangos.Y_log_min(i))^2;

    % Corrección log-normal → espacio real
    y_real(i)  = exp(mu_log + 0.5*s2_log);
    s2_real(i) = exp(2*mu_log + s2_log) .* (exp(s2_log) - 1);
end

end