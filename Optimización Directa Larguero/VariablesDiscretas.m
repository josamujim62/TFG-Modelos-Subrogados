function x=VariablesDiscretas(x)
allt=[0.0016 0.0023 0.0032 0.00483 0.00635 0.0127 0.019 0.0254 0.0381 0.0508];
allb=0.1:0.05:0.5;
h=0.4:0.1:1.2;
x(1)=allb(x(1));
x(2)=allt(x(2));
x(3)=allb(x(3));
x(4)=allt(x(4));
x(5)=h(x(5));
x(6)=allt(x(6));
end