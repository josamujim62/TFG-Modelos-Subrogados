function [c,ceq]=RestriccionesDiscretas_Kriging(x,mis_modelos,rangos)
x=VariablesDiscretas(x);
[c,ceq]=RestriccionesKriging(x,mis_modelos,rangos);
end