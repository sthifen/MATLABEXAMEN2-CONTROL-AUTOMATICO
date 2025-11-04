%% ================== PARTE 3 — Integral + Observador (planta s+1) ==================
clear; clc;

% -------- TU PLANTA: G(s) = (s+1)/(s^3 + 6 s^2 + 76 s + 13) --------
alpha = 6;  beta = 76;  gamma = 13;     
A = [0 1 0; 0 0 1; -gamma -beta -alpha];
B = [0;0;1];
C = [1 1 0];  D = 0;

assert(rank(ctrb(A,B))==3,'(A,B) no controlable.');
assert(rank(obsv(A,C))==3,'(A,C) no observable.');

% -------- Especificaciones (Base: Mp=20%, Ts=1s) ----------
Ts   = 1.0;
Mp   = 0.20;
zeta = sqrt((log(Mp))^2/(pi^2+(log(Mp))^2));
wn   = 4/(zeta*Ts);
sig  = zeta*wn;
wd   = wn*sqrt(1-zeta^2);

% ===================== Observadores (≈10× más rápidos) =====================
% BASE: par complejo 10×, tercer polo con magnitud 10×
p1o_b = 10*(-sig + 1j*wd);
p2o_b = conj(p1o_b);
p3o_b = -10*max(abs(real([p1o_b p2o_b])));
L_base = place(A',C',[p1o_b p2o_b p3o_b]).';

% CSO: tres reales (sin OS), 10× más rápidos y distintos
a_cso = 4/Ts;                     % rapidez nominal para CSO
pobs_c = -[10*a_cso  11*a_cso  12*a_cso];
L_cso  = place(A',C',pobs_c).';

% ===================== Integrador sobre error (Nise 12.8) ==================
% z_dot = r - Cx,  u = -Kx*xhat - Ki*z
Ai = [A, zeros(3,1); -C, 0];
Bi = [B; 0];

% Polos aumentados (TODOS distintos; incluye p3 = -1)
p_base_aug = [-sig+1j*wd, -sig-1j*wd, -1, -6*sig];       % BASE
p_cso_aug  = [-a_cso, -(1.2*a_cso), -1, -(3*a_cso)];     % CSO

Kaug_base = place(Ai, Bi, p_base_aug);
Kaug_cso  = place(Ai, Bi, p_cso_aug);

Kx_b = Kaug_base(1:3);   Ki_b = Kaug_base(4);
Kx_c = Kaug_cso (1:3);   Ki_c = Kaug_cso (4);

% ===================== Lazo completo (x, xhat, z) ======================
% Estados: X = [x; xhat; z],   u = -Kx*xhat - Ki*z
A_cl_base = [ A,           -B*Kx_b,                    -B*Ki_b;
              L_base*C,     A - B*Kx_b - L_base*C,     -B*Ki_b;
             -C,            zeros(1,3),                     0    ];
A_cl_cso  = [ A,           -B*Kx_c,                    -B*Ki_c;
              L_cso*C,      A - B*Kx_c - L_cso*C,      -B*Ki_c;
             -C,            zeros(1,3),                     0    ];
B_cl      = [zeros(3,1); zeros(3,1); 1];
C_cl      = [C, zeros(1,3), 0];
D_cl      = 0;

sys_int_base = ss(A_cl_base, B_cl, C_cl, D_cl);
sys_int_cso  = ss(A_cl_cso , B_cl, C_cl, D_cl);

% ----------------- Simulación (CI del enunciado) -----------------
t  = 0:1e-3:6;
r  = ones(size(t));
x0 = [0;0;0];  xhat0 = [1;5;2];  z0 = 0;   X0 = [x0; xhat0; z0];

yB = lsim(sys_int_base, r, t, X0);
yC = lsim(sys_int_cso , r, t, X0);

S_B = stepinfo(yB,t,1,'SettlingTimeThreshold',0.02);
S_C = stepinfo(yC,t,1,'SettlingTimeThreshold',0.02);

fprintf('\n=== PARTE 3 — Integral + Observador (α=6, β=76, γ=13; num=s+1) ===\n');
fprintf('BASE : Kx=[%.4f %.4f %.4f], Ki=%.4f | Ts=%.3fs, Mp=%.1f%%\n', ...
        Kx_b, Ki_b, S_B.SettlingTime, S_B.Overshoot);
fprintf('CSO  : Kx=[%.4f %.4f %.4f], Ki=%.4f | Ts=%.3fs, Mp=%.1f%%\n', ...
        Kx_c, Ki_c, S_C.SettlingTime, S_C.Overshoot);

% ----------------- Gráficas compactas -----------------
LW = 2.0;
figure('Name','P3: r->y (Integral + Observador)','Color','w');
subplot(2,1,1);
plot(t, r,'k:','LineWidth',1.2); hold on; grid on;
plot(t, yB,'b','LineWidth',LW);
plot(t, yC,'r--','LineWidth',LW);
ylabel('y(t)'); legend('r','Base','CSO','Location','southeast');
title('r -> y (integral sobre e=r-y)','Interpreter','none');

% Error de estimación ||x - xhat|| (para BASE)
sys_states_B = ss(A_cl_base, [B_cl zeros(7,1)], eye(7), zeros(7,2));
Xtraj_B = lsim(sys_states_B, [r(:) zeros(numel(t),1)], t, X0);
eB = Xtraj_B(:,1:3) - Xtraj_B(:,4:6);
subplot(2,1,2);
plot(t, vecnorm(eB,2,2),'b','LineWidth',LW); grid on;
xlabel('t [s]'); ylabel('||x - xhat||_2');
title('Convergencia del observador (BASE)','Interpreter','none');

% ====== Valores para tus tablas ======
K_BASE = Kx_b;   KE_BASE = Ki_b;   L_BASE = L_base;
K_CSO  = Kx_c;   KE_CSO  = Ki_c;   L_CSO  = L_cso;
