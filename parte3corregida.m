%% ================== PARTE 3 — Integral + Observador (corregida) ==================
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
a_cso = 4/Ts;
pobs_c = -[10*a_cso  11*a_cso  12*a_cso];
L_cso  = place(A',C',pobs_c).';

% ===================== Integrador sobre error (Nise 12.8) ==================
% z_dot = r_f - Cx,  u = -Kx*xhat - Ki*z
Ai = [A, zeros(3,1);
      -C, 0];
Bi = [B; 0];

% Polos aumentados (TODOS distintos) con polo integral explícito en -2
p_i = -2;                      % <- “más rápido”: puedes ajustar a -3,-4 si quieres
p_base_aug = [-sig+1j*wd, -sig-1j*wd, -1, p_i];            % BASE
p_cso_aug  = [-a_cso, -(1.2*a_cso), -1, p_i];              % CSO

Kaug_base = place(Ai, Bi, p_base_aug);
Kaug_cso  = place(Ai, Bi, p_cso_aug);

Kx_b = Kaug_base(1:3);   Ki_b = Kaug_base(4);   % <- Ke (para tu tabla) = Ki_b
Kx_c = Kaug_cso (1:3);   Ki_c = Kaug_cso (4);   % <- Ke (para tu tabla) = Ki_c

% ===================== Prefiltro (cancelar cero del numerador) =====================
s  = tf('s');
Hr = 1/(s+1);        % referencia filtrada r_f = (1 - e^{-t})
Hr_ss = ss(Hr);

% ===================== Anti-windup (opcional) =====================
% Saturación (cámbiala si tu actuador tiene límites reales)
u_min = -Inf;   % p.ej., -10
u_max =  Inf;   % p.ej., +10
k_aw  =  20;    % ganancia de back-calculation (si hay saturación)
use_aw = isfinite(u_min) || isfinite(u_max);  % por defecto queda OFF

% ===================== Simulación no lineal con ode45 =====================
t  = 0:1e-3:6;
r  = ones(size(t));
rf = lsim(Hr_ss, r, t);        % referencia filtrada

% Condiciones iniciales del enunciado:
x0 = [0;0;0];
xh0 = [1;5;2];
z0 = 0;

% ----- BASE -----
parB.A=A; parB.B=B; parB.C=C; parB.Kx=Kx_b; parB.Ki=Ki_b; parB.L=L_base;
parB.u_min=u_min; parB.u_max=u_max; parB.k_aw=k_aw; parB.use_aw=use_aw;
[tB,XB] = ode45(@(tt,XX) f_int_obs(tt,XX,t,rf,parB), t, [x0;xh0;z0]);
xB  = XB(:,1:3);  xhB = XB(:,4:6);  zB = XB(:,7);
yB  = (C*xB.').';

% ----- CSO -----
parC=parB; parC.Kx=Kx_c; parC.Ki=Ki_c; parC.L=L_cso;
[tC,XC] = ode45(@(tt,XX) f_int_obs(tt,XX,t,rf,parC), t, [x0;xh0;z0]);
xC  = XC(:,1:3);  xhC = XC(:,4:6);  zC = XC(:,7);
yC  = (C*xC.').';

% Métricas (sobre y(t), referencia unitaria)
S_B = stepinfo(yB,tB,1,'SettlingTimeThreshold',0.02);
S_C = stepinfo(yC,tC,1,'SettlingTimeThreshold',0.02);

fprintf('\n=== PARTE 3 — Integral + Observador (α=6, β=76, γ=13; num=s+1) ===\n');
fprintf('BASE : Kx=[%.4f %.4f %.4f],  Ke(Ki)=% .4f | Ts=%.3fs, Mp=%.1f%%\n', ...
        Kx_b, Ki_b, S_B.SettlingTime, S_B.Overshoot);
fprintf('CSO  : Kx=[%.4f %.4f %.4f],  Ke(Ki)=% .4f | Ts=%.3fs, Mp=%.1f%%\n', ...
        Kx_c, Ki_c, S_C.SettlingTime, S_C.Overshoot);

% ----------------- Gráficas compactas -----------------
LW = 2.0;
figure('Name','P3 corregida: r_f -> y (Integral + Observador)','Color','w');
subplot(2,1,1);
plot(t, rf,'k:','LineWidth',1.2); hold on; grid on;
plot(tB, yB,'b','LineWidth',LW);
plot(tC, yC,'r--','LineWidth',LW);
ylabel('y(t)'); legend('r_f','Base','CSO','Location','southeast');
title('r_f \rightarrow y (integral sobre e=r_f - y)','Interpreter','tex');

subplot(2,1,2);
eB = xB - xhB;  eC = xC - xhC;
plot(t, vecnorm(eB,2,2),'b','LineWidth',LW); hold on; grid on;
plot(t, vecnorm(eC,2,2),'r--','LineWidth',LW);
xlabel('t [s]'); ylabel('||x - \hat{x}||_2');
title('Convergencia del observador');

% ====== Valores para TUS TABLAS ======
K_BASE = Kx_b;   KE_BASE = Ki_b;   L_BASE = L_base;
K_CSO  = Kx_c;   KE_CSO  = Ki_c;   L_CSO  = L_cso;

% ===================== Dinámica no lineal (anti-windup) ===================
function dX = f_int_obs(tt, X, tgrid, rf_vec, P)
% X = [x; xhat; z]
x   = X(1:3);
xh  = X(4:6);
z   = X(7);

% referencia filtrada en el tiempo actual
rf  = interp1(tgrid, rf_vec, tt, 'linear', 'extrap');

% salida y, yhat
y   = P.C*x;
yh  = P.C*xh;

% control "no saturado"
u_lin = -P.Kx * xh - P.Ki * z;

% saturación (opcional)
if P.use_aw
    u_sat = min(max(u_lin, P.u_min), P.u_max);
    u     = u_sat;
    % back-calculation
    z_aw  = P.k_aw * (u_sat - u_lin);
else
    u     = u_lin;
    z_aw  = 0;
end

% dinámica
xdot   = P.A*x  + P.B*u;
xh_dot = P.A*xh + P.B*u + P.L*(y - yh);
zdot   = (rf - y) + z_aw;          % <- anti-windup entra por z_aw

dX = [xdot; xh_dot; zdot];
end
