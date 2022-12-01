function CA = getCA(firing_rate, col, row)

% get CA

CA_x = sum(firing_rate.*(col-4.5)) / sum(firing_rate);
CA_y = sum(firing_rate.*(row-4.5)) / sum(firing_rate);

CA = [CA_x, CA_y];

end