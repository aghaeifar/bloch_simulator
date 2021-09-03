% Constants 
gamma   = 267522187.44;
gamma_hz= gamma/2/pi;
FA      = 45 * pi/180;
ntime   = 400; % number of samples
rf_len  = 4e-3; % second
td      = rf_len/ntime; %  dwell time 
ncoil   = 8;
voxel_sz= [3, 3, 3] * 1e-3;
fov     = [-60 45; -30 70; -90 90] * 1e-3;
rf_tbw  = 12;
is_sinc = false;
is_selective = false;

% positions
[prx, pry, prz] = ndgrid(fov(1,1):voxel_sz(1):fov(1,2), fov(2,1):voxel_sz(2):fov(2,2), fov(3,1):voxel_sz(3):fov(3,2));
sz      = size(prz);
pr      = transpose([prx(:), pry(:), prz(:)]);
npos    = size(pr, 2); % number of spatial positions

% off-resonance
b0 = zeros(npos, 1);

% sinc pulse
if is_sinc
    t = linspace(-rf_len/2, rf_len/2, ntime); % must be column
    BW = rf_tbw/rf_len;
    x  = pi*t*BW + eps; % didn't use 2pi -> we are interested in full BW not only the positive
    snc = sin(x) ./ x; 
    hamming_window = 0.53836 + 0.46164*cos(2*pi * linspace(-0.5,0.5,ntime));
    rf = transpose(snc .* hamming_window);
    rf = repmat(rf / sum(rf), [1 ncoil]); % normalize
    b1 = complex(rf * FA/gamma/td/ncoil);
else
    b1 = complex(ones(ntime, ncoil) * FA/gamma/rf_len/ncoil) ;
end
sens = complex(ones(ncoil, npos));

% gradients
gr = zeros(3, ntime);
if is_selective
    BW = rf_tbw/rf_len; % [Hz]
    gr(3, :) = BW / voxel_sz(3) / gamma_hz;
end

m0 = [zeros(2, npos); ones(1, npos)];

% run
b1 = real(b1) + 1i*real(b1);
b1 = b1 / sqrt(2);
result    = bloch_sim_mex(b1, gr, td, b0, pr, 10000, 10000, sens, m0);
result_xy = reshape(result(1,:), sz) + 1j*reshape(result(2,:), sz);
result_z  = reshape(result(3,:), sz);