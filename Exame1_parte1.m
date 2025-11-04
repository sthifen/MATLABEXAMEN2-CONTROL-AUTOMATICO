% ==== Polinomio de segundo orden y ecuación característica deseada ====
zeta   = 0.456;
omega_n = 8.773;

% Polinomio de segundo orden dominante
num2 = [1  2*zeta*omega_n  omega_n^2];   % s^2 + 2ζωn s + ωn^2

% Polo adicional (por ejemplo, en -5)
p3 = 5;                                   % (s + 5)

% Polinomio total
poly_total = conv(num2, [1 p3]);          % (s^2 + ...)*(s + 5)

disp('Ecuación característica deseada (coeficientes):')
disp(poly_total)

fprintf('Polinomio expandido:\n')
fprintf('s^3 + %.3f s^2 + %.3f s + %.3f = 0\n', ...
        poly_total(2), poly_total(3), poly_total(4));
