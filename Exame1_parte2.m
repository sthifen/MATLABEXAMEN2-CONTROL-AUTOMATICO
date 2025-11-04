%% ================= PUNTO 2.2 — Simulación controlador + observador =================
clear; clc; close all;  s = tf('s');

% --- Planta: G(s) = (s+1)/(s^3 + 6 s^2 + 76 s + 13)
A = [  0   1   0;
       0   0   1;
     -13 -76  -6 ];
B = [0;0;1];
C = [1 1 0];     % <-- num = s + 1
D = 0;

% Prefiltro para cancelar el cero del numerador (nuevo enunciado)
Hr = 1/(s+1);  Hr_ss = ss(Hr);

% ==================== Ganancias dadas (Punto 2.1) ====================
% BASE
K_base = [3065.55  320.964  42];
L_base = [115088; -114136; 186232];

% SIN SOBREIMPULSO
K_crit = [679.999  278.303  43.29];
L_crit = [12526.1; -12016.7; 46971.2];

% ==================== Referencias y condiciones iniciales ====================
t  = 0:1e-3:5;
r  = ones(size(t));                  % escalón unitario
rf = lsim(Hr_ss, r, t);              % referencia filtrada (cancela el cero)

x0    = [0;0;0];
xhat0 = [1;5;2];
e0    = x0 - xhat0;                  % e = x - xhat
x0_aug = [x0; e0];

% ==================== BASE: combinado control + observador ====================
Acl_b  = A - B*K_base;
N_base = 1/( C*((-Acl_b)\B) );

Aaug_b = [A - B*K_base,   B*K_base;
          zeros(3),       A - L_base*C];
Baug_b = [B*N_base; zeros(3,1)];
Caug   = [C, zeros(1,3)];
Daug   = 0;

sys_aug_b = ss(Aaug_b, Baug_b, Caug, Daug);
y_b = lsim(sys_aug_b, rf, t, x0_aug);

% ==================== SIN-OS: combinado control + observador ====================
Acl_c  = A - B*K_crit;
N_crit = 1/( C*((-Acl_c)\B) );

Aaug_c = [A - B*K_crit,   B*K_crit;
          zeros(3),       A - L_crit*C];
Baug_c = [B*N_crit; zeros(3,1)];

sys_aug_c = ss(Aaug_c, Baug_c, Caug, Daug);
y_c = lsim(sys_aug_c, rf, t, x0_aug);

% ==================== Métricas (r->y con Hr), para reporte ====================
T_base_y = minreal( tf(ss(Acl_b, B*N_base, C, 0)) * Hr );
T_crit_y = minreal( tf(ss(Acl_c, B*N_crit, C, 0)) * Hr );
S_b = stepinfo(T_base_y, 'SettlingTimeThreshold', 0.02);
S_c = stepinfo(T_crit_y, 'SettlingTimeThreshold', 0.02);

fprintf('\n=== PUNTO 2.2 — Resultados (con tus K y L; num=s+1, Hr=1/(s+1)) ===\n');
fprintf('BASE : Mp = %.1f %% | Ts(2%%) = %.3f s\n', S_b.Overshoot, S_b.SettlingTime);
fprintf('SINOS: Mp = %.1f %% | Ts(2%%) = %.3f s\n', S_c.Overshoot, S_c.SettlingTime);

% ==================== Gráficas ====================
figure('Name','P2.2 - BASE: controlador + observador');
subplot(2,1,1);
plot(t, rf, 'k--', 'LineWidth',1.1); hold on;
plot(t, y_b, 'LineWidth',1.6); grid on; hold off;
ylabel('y(t)'); title(sprintf('BASE: r→y (con Hr), Mp=%.1f%%, Ts=%.3fs', S_b.Overshoot, S_b.SettlingTime));
legend('r_f','y','Location','best');

subplot(2,1,2);
e_traj_b = lsim(ss(A-L_base*C, zeros(3,1), eye(3), 0), zeros(size(t)), t, e0);
plot(t, e_traj_b, 'LineWidth',1.2); grid on;
xlabel('t [s]'); ylabel('e = x - \hat{x}');
title('BASE: convergencia del observador');

figure('Name','P2.2 - SIN OS: controlador + observador');
subplot(2,1,1);
plot(t, rf, 'k--', 'LineWidth',1.1); hold on;
plot(t, y_c, 'LineWidth',1.6); grid on; hold off;
ylabel('y(t)'); title(sprintf('SIN OS: r→y (con Hr), Mp=%.1f%%, Ts=%.3fs', S_c.Overshoot, S_c.SettlingTime));
legend('r_f','y','Location','best');

subplot(2,1,2);
e_traj_c = lsim(ss(A-L_crit*C, zeros(3,1), eye(3), 0), zeros(size(t)), t, e0);
plot(t, e_traj_c, 'LineWidth',1.2); grid on;
xlabel('t [s]'); ylabel('e = x - \hat{x}');
title('SIN OS: convergencia del observador');
