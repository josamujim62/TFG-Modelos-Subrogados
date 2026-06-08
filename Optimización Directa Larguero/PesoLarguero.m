function W = PesoLarguero(x)
    res = EjecutarAnsys(x); % Llama a nuestra nueva función
    W = res(4);             % Extrae la posición 4 (el peso)
end