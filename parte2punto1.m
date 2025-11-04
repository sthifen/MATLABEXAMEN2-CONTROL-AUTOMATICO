%% ======================= PUNTO 1: OBSERVADORES =========================

clear; clc;

%% --- Planta en canónica controlable ---
A = [  0   1   0;
       0   0   1;
     -13 -76  -6];
B = [0;0;1];
C = [1 1 0];                 
D = 0;

% Comprobaciones
assert(rank(ctrb(A,B))==3,'Sistema no controlable.');
assert(rank(obsv(A,C))==3,'Sistema no observable.');

%% ===================== Controlador BASE (referencia) ====================
Mp   = 0.20;            % 20 %
Ts   = 1.0;             % 2 % criterio
zeta = fzero(@(z) exp(-pi*z./sqrt(1-z.^2)) - Mp, 0.45);
wn   = 4/(zeta*Ts);
sigma = zeta*wn;                       % >0
wd    = wn*sqrt(1 - zeta^2);

% Polos deseados del controlador BASE
p1 = -sigma + 1j*wd;
p2 = conj(p1);
p3 = -10*sigma;
d  = poly([p1 p2 p3]);                 % [1 a2 a1 a0]

% Ganancia K del BASE (independiente de C)
K_base = [d(4)-13, d(3)-76, d(2)-6];

%% --------- OBSERVADOR para el BASE (10× más rápido, sin repetidos) ------
pobs_pair_base = 10*[p1 p2];                          % -10σ ± j10ωd
pobs3_base     = -10*max(abs(pobs_pair_base));        % magnitud 10× la del par
p_obs_base     = [pobs_pair_base, pobs3_base];

L_base = place(A', C', p_obs_base).';                 % <-- usa C corregida

%% =========== Controlador SIN SOBREIMPULSO (ζ=1, Ts≈1 s) =================
% Usa tu a_opt (ajústalo si tu Parte 1.2 dio otro)
a_opt  = 4.1075;
dcrit  = poly([-a_opt, -a_opt, -10*a_opt]);
K_crit = [dcrit(4)-13, dcrit(3)-76, dcrit(2)-6];

%% ----- OBSERVADOR para el SIN-OS (10× más rápido, sin repetidos) -------
% Evitamos polos repetidos (place no acepta multiplicidad > rank(C))
pcrit1 = -a_opt;
pcrit2 = -1.05*a_opt;                                  % pequeño offset
pcrit3 = -10*a_opt;

pobs_pair_crit = 10*[pcrit1 pcrit2];                   % ~[-10a, -10.5a]
pobs3_crit     = -10*max(abs(pobs_pair_crit));         % magnitud 10× la del par
p_obs_crit     = [pobs_pair_crit, pobs3_crit];

L_crit = place(A', C', p_obs_crit).';                  % <-- usa C corregida

%% ========================== Reporte en consola ==========================
fprintf('\n=== PUNTO 2.1: DISEÑO DE OBSERVADORES (num = s+1) ===\n');

fprintf('\n-- BASE --\n');
fprintf('Polos controlador: %s\n', mat2str([p1 p2 p3],4));
fprintf('Polos observador : %s\n', mat2str(p_obs_base,4));
fprintf('K_base = [%g  %g  %g]\n', K_base);
fprintf('L_base = [%g; %g; %g]\n', L_base);

fprintf('\n-- SIN SOBREIMPULSO (ζ=1) --\n');
fprintf('a_opt = %.4f\n', a_opt);
fprintf('Polos controlador: %s\n', mat2str([-a_opt -a_opt -10*a_opt],4));
fprintf('Polos observador : %s\n', mat2str(p_obs_crit,4));
fprintf('K_crit = [%g  %g  %g]\n', K_crit);
fprintf('L_crit = [%g; %g; %g]\n', L_crit);

% Validaciones rápidas: estabilidad de A-LC
eig_base = eig(A - L_base*C).';
eig_crit = eig(A - L_crit*C).';
fprintf('\nAutovalores(A-LC) BASE : %s\n',  mat2str(eig_base,4));
fprintf('Autovalores(A-LC) SINOS: %s\n\n', mat2str(eig_crit,4));
