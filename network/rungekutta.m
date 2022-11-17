function y = rungekutta(dxdt,h,y0)
    k1=dxdt(y0);
    k2=dxdt(y0+0.5*h*k1);
    k3=dxdt(y0+0.5*h*k2);
    k4=dxdt(y0+h*k3);
    y=y0+h/6*(k1+2*k2+2*k3+k4);
end