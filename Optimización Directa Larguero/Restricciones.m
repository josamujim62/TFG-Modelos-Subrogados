function [c,ceq]=Restricciones(x)
L_spar=8;
res = EjecutarAnsys(x);
c=zeros(1,3);
c(1)=res(1)-455e6;
c(2)=res(2)-(L_spar/25);
c(3)=1.5-res(3);
ceq=[];
end