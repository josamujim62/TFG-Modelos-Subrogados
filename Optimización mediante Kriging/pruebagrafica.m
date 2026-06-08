clc
clear
close
%
% Data Base generator. LARGUERO
%

n_fac=8; % number of parameters 
n_cas=10;
n_tri=1000;
n_rows=n_fac+4; % number of parameters + number of outputs
%
db_datos=zeros(n_cas,n_rows);
tic
dRE = lhsdesign(n_cas,n_fac,"criterion","maximin","iterations",n_tri);
%     b_upp  t_upp b_low t_low   h    t_web d_hole s
lb = [0.2 0.00483  0.2 0.00483  0.4  0.00483 0.15 0.4]; 
ub = [0.5  0.0508  0.5  0.0508  1.2  0.0508  0.65 2.5];
t1=toc;
fprintf('El tiempo empleado en generar la matriz de muestras es de %d segundos',t1);
dRE_norm = dRE; % Guardamos la versión 0-1 por si acaso
dRE = lb + (ub - lb) .* dRE_norm;
db_datos(:,1:n_fac)=dRE;
tic
for i=1:n_cas
    dlmwrite('VARINPUTSUB.txt', db_datos(i, 1:n_fac)' , 'delimiter', '\t', 'precision', '%4.5f');
    dos('"C:\Program Files\ANSYS Inc\ANSYS Student\v252\ansys\bin\winx64\ansys252.exe" -b -dir "C:\Users\josam\Documents\GIA\TFG\3.LARGUERO FEM\1. ENTRENAMIENTO Y CREACION SURROGADO" -i "LARGUEROSUB.txt" -o "ResultadosoptimSUB.out"');
    Resultados=load('Resultados_Out_SUB.txt');
    Resultados=Resultados(~isnan(Resultados));
    db_datos(i,9)=Resultados(1);
    db_datos(i,10)=Resultados(2);
    db_datos(i,11)=Resultados(3);
    db_datos(i,12)=Resultados(4);
end
%
t2=toc;
fprintf('El tiempo empleado en calcular los resultados en ANSYS es de %d horas',t2/3600);
X=dRE_norm;
Y=db_datos(:,9:12);
[Y_temp, ps_y] = mapminmax(Y');
Y_norm=Y_temp';
save pruebagrafica.mat X Y Y_norm ps_y dRE