%% =================== PARTE 3: Consumo de energía ( ===================
% Planta: G(s) = (s+1) / (s^3 + 6 s^2 + 76 s + 13)
clear; clc; close all;  s = tf('s');
alpha = 6;  beta = 76;  gamma = 13;

A = [0 1 0; 
     0 0 1; 
    -gamma -beta -alpha];
B = [0;0;1];
C = [1 1 0];     
D = 0;

% Prefiltro para cancelar el cero
Hr = 1/(s+1);   

%% ---------- Controlador BASE (Mp=20%, Ts=1s, tercer polo 10×) ----------
Mp = 0.20;  Ts_des = 1.0;
zeta = -log(Mp)/sqrt(pi^2 + (log(Mp))^2);
wn   = 4/(zeta*Ts_des);
sigma =  zeta*wn;
wd    =  wn*sqrt(1 - zeta^2);
p3    = 10*sigma;

d      = poly([-(sigma)+1j*wd, -(sigma)-1j*wd, -p3]);              % [1 d2 d1 d0]
K_base = [d(4)-gamma, d(3)-beta, d(2)-alpha];
Acl_b  = A - B*K_base;
N_base = 1 / ( C*((-Acl_b)\B) );

% r -> y con Hr (para métricas coherentes)
T_base_y = minreal( tf(ss(Acl_b, B*N_base, C, 0)) * Hr );

%% ---------- Controlador SIN SOBREIMPULSO (ζ=1), Ts≈Ts_des ----------
% Polos [-a,-a,-10a], ajustamos 'a' para que Ts(2%) ≈ Ts_des (con Hr)
a_init = 4/Ts_des;                         % 2º orden crítico: Ts≈4/a
a_opt  = a_init;
try
    a_opt = fzero(@(a) cost_Ts(a,A,B,C,Hr,Ts_des,alpha,beta,gamma), a_init);
catch, end

dcrit     = poly([-a_opt, -a_opt, -10*a_opt]);
K_crit    = [dcrit(4)-gamma, dcrit(3)-beta, dcrit(2)-alpha];
Acl_c     = A - B*K_crit;
N_crit    = 1 / ( C*((-Acl_c)\B) );

% r -> y con Hr (para métricas coherentes)
T_crit_y  = minreal( tf(ss(Acl_c, B*N_crit, C, 0)) * Hr );

%% ---------- Tomar Ts (2%) desde r->y con Hr ----------
info_b = stepinfo(T_base_y, 'SettlingTimeThreshold', 0.02);
info_c = stepinfo(T_crit_y, 'SettlingTimeThreshold', 0.02);
Ts_b   = max(info_b.SettlingTime, 0.5);
Ts_c   = max(info_c.SettlingTime, 0.5);

%% ---------- r -> u (SIN Hr) y energía con R = 1 Ω ----------
% u(t) es la salida del controlador; modelamos r->u como ss(Acl,B*N,-K,N)
T_base_u = ss(Acl_b, B*N_base, -K_base, N_base);
T_crit_u = ss(Acl_c, B*N_crit, -K_crit, N_crit);

dt = 1e-3;
t_b = 0:dt:Ts_b;
t_c = 0:dt:Ts_c;

u_b = step(T_base_u, t_b);  u_b = u_b(:).';
u_c = step(T_crit_u, t_c);  u_c = u_c(:).';

% v(t) = ∫ u(t) dt ;   E = ∫ v^2(t) dt   (R=1 Ω)
v_b = cumtrapz(t_b, u_b);
v_c = cumtrapz(t_c, u_c);
E_b = trapz(t_b, v_b.^2);
E_c = trapz(t_c, v_c.^2);
ratio = E_b / E_c;

%% ---------- Resultados ----------
fprintf('\n=== PARTE 3: ENERGÍA (r->u SIN Hr; Ts desde r->y CON Hr) ===\n');
fprintf('BASE : Mp=%.1f%%, Ts(2%%)=%.3fs\n', info_b.Overshoot, Ts_b);
fprintf('SINOS: Mp=%.1f%%, Ts(2%%)=%.3fs\n', info_c.Overshoot, Ts_c);
fprintf('E_base = %.6f J   |   E_crit = %.6f J   |  E_base/E_crit = %.3f\n', E_b, E_c, ratio);
if ratio > 1
    fprintf('>> El Controlador BASE consume MÁS energía (%.1f%% más).\n', (ratio-1)*100);
else
    fprintf('>> El Controlador SIN-OS consume más (%.1f%% más).\n', (1/ratio-1)*100);
end

%% ---------- Gráficas ----------
figure('Name','u(t) y v(t)');
subplot(2,1,1);
plot(t_b, u_b, 'LineWidth',1.6); hold on;
plot(t_c, u_c, 'LineWidth',1.6); grid on;
xlabel('t [s]'); ylabel('u(t)');
title('Salida del controlador u(t) (SIN Hr en r\rightarrow u)');
legend('Base','Sin OS','Location','best');

subplot(2,1,2);
plot(t_b, v_b, 'LineWidth',1.6); hold on;
plot(t_c, v_c, 'LineWidth',1.6); grid on;
xlabel('t [s]'); ylabel('v(t) = \int u(t) dt');
title('Tensión equivalente v(t) sobre 1 \Omega');
legend('Base','Sin OS','Location','best');

%% ---------- Helper: costo de Ts (usa r->y con Hr) ----------
function val = cost_Ts(a, A,B,C,Hr,Ts_obj,alpha,beta,gamma)
    d = poly([-a, -a, -10*a]);                % [1 a2 a1 a0]
    K = [d(4)-gamma, d(3)-beta, d(2)-alpha];  % comparación de coeficientes
    Acl = A - B*K;
    N   = 1 / ( C * ((-Acl)\B) );
    Tyy = minreal( tf(ss(Acl, B*N, C, 0)) * Hr );
    info = stepinfo(Tyy, 'SettlingTimeThreshold', 0.02);
    val  = info.SettlingTime - Ts_obj;
end
