%% ===== Punto 4 – Ancho de banda y muestreo (NUM = s+1) =====
clear; clc; close all; s = tf('s');

% Planta: G(s) = (s+1)/(s^3 + 6 s^2 + 76 s + 13)
alpha=6; beta=76; gamma=13;
A = [0 1 0; 0 0 1; -gamma -beta -alpha];
B = [0;0;1];
C = [1 1 0];   
D = 0;

% Prefiltro para cancelar el cero (permitido)
Hr = 1/(s+1);  

%% --- Controlador BASE (Mp=20%, Ts=1s, 3er polo 10×) ---
Mp = 0.20; Ts_des = 1.0;
zeta = -log(Mp)/sqrt(pi^2+(log(Mp))^2);
wn   = 4/(zeta*Ts_des);
sigma =  zeta*wn;  wd = wn*sqrt(1-zeta^2);
p3    = 10*sigma;

d      = poly([-(sigma)+1j*wd, -(sigma)-1j*wd, -p3]); % [1 d2 d1 d0]
K_base = [d(4)-gamma, d(3)-beta, d(2)-alpha];
Acl_b  = A - B*K_base;
N_base = 1/( C*((-Acl_b)\B) );

% r -> y con Hr
T_base_y = minreal( tf(ss(Acl_b,B*N_base,C,0)) * Hr );

%% --- Controlador SIN SOBREIMPULSO (ζ=1), ajustado a Ts≈1s ---
a_opt = 6.0979;   % <-- usa tu 'a_opt' obtenido con (s+1)
dcrit  = poly([-a_opt, -a_opt, -10*a_opt]);
K_crit = [dcrit(4)-gamma, dcrit(3)-beta, dcrit(2)-alpha];
Acl_c  = A - B*K_crit;
N_crit = 1/( C*((-Acl_c)\B) );

% r -> y con Hr
T_crit_y = minreal( tf(ss(Acl_c,B*N_crit,C,0)) * Hr );

%% --- Bandwidth (-3 dB) y muestreo ---
wb_base = bandwidth(T_base_y);  fb_base = wb_base/(2*pi);
wb_crit = bandwidth(T_crit_y);  fb_crit = wb_crit/(2*pi);

fs_min_base = 2*fb_base;   fs_rec_base = 10*fb_base;   Tctrl_base = 1/fs_rec_base;
fs_min_crit = 2*fb_crit;   fs_rec_crit = 10*fb_crit;   Tctrl_crit = 1/fs_rec_crit;

S_base = stepinfo(T_base_y,'SettlingTimeThreshold',0.02);
S_crit = stepinfo(T_crit_y,'SettlingTimeThreshold',0.02);

fprintf('\n=== PUNTO 4: ANCHO DE BANDA Y MUESTREO (num = s+1) ===\n');
fprintf('BASE : Mp=%.1f%%, Ts=%.3fs | BW = %.4f rad/s (%.4f Hz)\n', ...
        S_base.Overshoot, S_base.SettlingTime, wb_base, fb_base);
fprintf('       fs_min = %.4f Hz | fs_rec(10x) = %.4f Hz | T_ctrl = %.5f s\n', ...
        fs_min_base, fs_rec_base, Tctrl_base);

fprintf('SINOS: Mp=%.1f%%, Ts=%.3fs | BW = %.4f rad/s (%.4f Hz)\n', ...
        S_crit.Overshoot, S_crit.SettlingTime, wb_crit, fb_crit);
fprintf('       fs_min = %.4f Hz | fs_rec(10x) = %.4f Hz | T_ctrl = %.5f s\n', ...
        fs_min_crit, fs_rec_crit, Tctrl_crit);

if fb_base > fb_crit
    fprintf('>> El CONTROLADOR BASE requiere mayor ancho de banda y mayor fs.\n');
elseif fb_base < fb_crit
    fprintf('>> El CONTROLADOR SIN-OS requiere mayor ancho de banda y mayor fs.\n');
else
    fprintf('>> Ambos controladores tienen ancho de banda equivalente.\n');
end

% Bode para el informe
figure; bode(T_base_y); grid on; title('Bode r \rightarrow y - BASE (con Hr = 1/(s+1))');
figure; bode(T_crit_y); grid on; title('Bode r \rightarrow y - SIN OS (con Hr = 1/(s+1))');
