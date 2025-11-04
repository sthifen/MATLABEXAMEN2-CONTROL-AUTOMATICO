# MATLABEXAMEN2-CONTROL-AUTOMATICO
# 📘 Documentación Matemática del Controlador por Realimentación de Estados

Este repositorio contiene la documentación técnica, simulaciones y resultados del diseño de controladores por realimentación de estados, observadores de Luenberger y control integral para la asignatura **Control Automático**.

El proyecto se desarrolla en **MATLAB/Simulink** y se presenta en formato **IEEE doble columna**, incluyendo análisis temporal, energético y frecuencial.

---

## 📄 Descripción general

El documento principal en LaTeX es:

https://es.overleaf.com/read/rxtrrstbfdrq#8f73d9


tabla que nos pide el profesor
https://www.overleaf.com/read/dsbbsbwwhhsy#9cd072
Este archivo contiene todo el desarrollo teórico y matemático, incluyendo:
- Diseño del **controlador base** por asignación de polos  
- Diseño de un **controlador sin sobreimpulso (amortiguamiento crítico)**  
- **Análisis energético** del esfuerzo de control  
- **Análisis de ancho de banda y frecuencia de muestreo**  
- Diseño de **observadores de Luenberger** para ambos controladores  
- Integración completa **Controlador + Observador**  
- Extensión con **acción integral** y diagnóstico de inestabilidad  
- **Propuestas de corrección** (reubicación de polos, anti-windup, prefiltro, LQR)

---

## 🧮 Estructura del proyecto

| Carpeta / Archivo | Descripción |
|--------------------|-------------|
| `controladores_realimentacion_estado.tex` | Documento principal en formato IEEE doble columna |
| `figuras/` | Carpeta que contiene todas las figuras usadas (sin cambiar nombres) |
| `matlab_scripts/` | Códigos `.m` usados para simulación y obtención de resultados |
| `README.md` | Este archivo |
| `Control Systems Engineering - Nise 7th etext.pdf` | Libro base de referencia |

---

## 🧠 Resumen del contenido

### Parte 1 – Controladores por realimentación de estados
- Diseño de controladores mediante **asignación de polos**
- Cálculo de ganancias \( K \) y ganancia de prealimentación \( N \)
- Verificación de desempeño ( \( M_p, T_s, e_{ss} \) )
- Prefiltro para cancelación de cero no deseado

### Parte 2 – Observadores de estado
- Diseño de **observadores de Luenberger**
- Aplicación del **principio de separación**
- Validación por simulación: sistema completo (planta + controlador + observador)
- Comparación de desempeño con diferentes condiciones iniciales

### Parte 3 – Control Integral
- Inclusión del **estado integral del error**
- Diseño de controladores aumentados (4 estados)
- Diagnóstico de **sobreimpulso anómalo**
- Propuestas de corrección: anti-windup, prefiltro, LQR

---

## ⚙️ Requerimientos

- **Compilador LaTeX:** `pdflatex` o `xelatex`  
- **Paquetes IEEE:** `IEEEtran`, `amsmath`, `graphicx`, `babel`, `cite`, `balance`, `float`, `booktabs`
- **Software de simulación:** MATLAB R2023a o superior

---

## 📈 Resultados principales

| Controlador | \(M_p\) | \(T_s\) [s] | Energía [J] | Comentario |
|--------------|---------|--------------|--------------|-------------|
| BASE | 19.5% | 0.974 | 5868.15 | Respuesta rápida con sobreimpulso |
| SIN-OS | 0.0% | 1.000 | 3813.53 | Crítico, sin sobreimpulso |
| Integral (original) | 695% | 1.538 | — | Respuesta inestable, requiere ajuste |

El **controlador SIN SOBREIMPULSO** es el más eficiente energéticamente (−53.9 % consumo).

---

## 🔍 Referencia bibliográfica

> **[1]** N. S. Nise, *Control Systems Engineering*, 7th ed. Hoboken, NJ, USA: John Wiley & Sons, 2015.  
> ISBN 978-1-118-17051-9 (print), 978-1-118-80082-9 (pdf)

---

## 👤 Autor

**Steven Andrey Fonseca Bermúdez**  
Estudiante de Ingeniería Electrónica – Instituto Tecnológico de Costa Rica  
Curso: *Control Automático (Controladores)*  

---

## 🧾 Licencia

Este trabajo académico se publica con fines educativos y de documentación.  
Todo el contenido y las figuras se mantienen con sus nombres originales según la entrega oficial del curso.
