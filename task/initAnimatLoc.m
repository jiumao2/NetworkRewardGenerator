function loc_animat = initAnimatLoc(r_inner)

    rho = randsrc(1, 1, [0:.1:r_inner-.1; (0:.1:r_inner-.1).^2 / sum((0:.1:r_inner-.1).^2)]);
    theta = pi * (2*rand()-1);
    
    [x, y] = pol2cart(theta, rho);
    loc_animat = [x, y];

end