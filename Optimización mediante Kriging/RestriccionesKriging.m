function [c,ceq]=RestriccionesKriging(x,mis_modelos,rangos)
[y_real,~]=PrediccionKriging(x,mis_modelos,rangos);
L_spar=8;
c=zeros(1,3);
c(1)=y_real(1)-455e6;
c(2)=y_real(2)-(L_spar/25);
c(3)=1.5-y_real(3);
ceq=[];
end