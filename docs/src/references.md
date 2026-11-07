# References

## Option pricing

- F. Black and M. Scholes, *The Pricing of Options and Corporate Liabilities*, Journal of Political Economy 81(3),
  637–654, 1973. The Black and Scholes model ([Pricing and Greeks](pricing.md)).
- F. Black, *The Pricing of Commodity Contracts*, Journal of Financial Economics 3(1–2), 167–179, 1976. The Black model,
  options on forwards.

## Implied volatility

- P. Jäckel, *Let's Be Rational*, Wilmott 2015(75), 40–53, 2015, and the revised version of 2024 on
  [jaeckel.org](http://www.jaeckel.org/LetsBeRational.pdf), implemented by [`blsimpv`](@ref) and [`blkimpv`](@ref):
  rational initial guesses and at most two Householder iterations ([Implied volatility](implied_volatility.md)).

## Implicit function theorem

- U. Dini, *Analisi infinitesimale*, lectures at the University of Pisa, academic year 1877–78 (first given in 1876–77),
  pages 180–195; printed as *Lezioni di analisi infinitesimale*, volume 1, Fratelli Nistri, Pisa, 1907, pages
  197–241. The implicit function theorem for functions of several variables, known as Dini's theorem in Italy.
- G. Mingari Scarpello and D. Ritelli, *A Historical Outline of the Theorem of Implicit Functions*, Divulgaciones
  Matemáticas 10(2), 171–180, 2002.
- S. G. Krantz and H. R. Parks, *The Implicit Function Theorem: History, Theory, and Applications*, Birkhäuser, 2002.
  The history of the theorem, from Lagrange and Cauchy to Dini, and its modern forms.
- W. Rudin, *Principles of Mathematical Analysis*, 3rd edition, McGraw-Hill, 1976, Theorem 9.28.

It gives the derivatives of the implied volatility without differentiating the solver
([Automatic differentiation](ad.md#Derivatives-of-the-implied-volatility)), and the sensitivities of calibrated
parameters to the market quotes ([GPU and calibration](gpu.md#Sensitivity-of-the-calibrated-parameters-to-the-quotes)).

- M. Blondel, Q. Berthet, M. Cuturi, R. Frostig, S. Hoyer, F. Llinares-López, F. Pedregosa and J.-P. Vert,
  *Efficient and Modular Implicit Differentiation*, Advances in Neural Information Processing Systems 35, 2022. The
  same idea for the solutions of optimisation problems and of root finding, in automatic differentiation.

## Automatic differentiation

- A. Griewank and A. Walther, *Evaluating Derivatives: Principles and Techniques of Algorithmic Differentiation*, 2nd
  edition, SIAM, 2008. Forward and reverse mode, Taylor series arithmetic, and Newton's method on truncated series.
- M. Giles and P. Glasserman, *Smoking Adjoints: Fast Monte Carlo Greeks*, Risk 19(1), 88–92, 2006.
- L. Capriotti, *Fast Greeks by Algorithmic Differentiation*, Journal of Computational Finance 14(3), 3–35, 2011.
- W. Squire and G. Trapp, *Using Complex Variables to Estimate Derivatives of Real Functions*, SIAM Review 40(1),
  110–112, 1998. The complex step, which needs the analytic continuation of the implied volatility
  ([Implied volatility](implied_volatility.md#Complex-numbers)).
- J. R. R. A. Martins, P. Sturdza and J. J. Alonso, *The Complex-Step Derivative Approximation*, ACM Transactions on
  Mathematical Software 29(3), 245–262, 2003.

## Calibration

- J. Nocedal and S. J. Wright, *Numerical Optimization*, 2nd edition, Springer, 2006, Chapter 10: nonlinear least
  squares and the Gauss–Newton method ([GPU and calibration](gpu.md#A-calibration)).

## Dates

- MathWorks, Financial Toolbox documentation of
  [`yearfrac`](https://www.mathworks.com/help/finance/yearfrac.html): the day count conventions selected by `basis`
  ([Dates](dates.md)).
