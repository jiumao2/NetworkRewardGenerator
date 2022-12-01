function Quadrant = getQuadrant(Location)

N = size(Location, 1);
Quadrant = zeros(N,1);
for i = 1:N
    theta = cart2pol(Location(i,1), Location(i,2));
    if theta>=0 && theta<pi/2
        Quadrant(i) = 1;
    elseif theta>=pi/2
        Quadrant(i) = 2;
    elseif theta<-pi/2
        Quadrant(i) = 3;
    elseif theta<0 && theta>=-pi/2
        Quadrant(i) = 4;
    end
end

end