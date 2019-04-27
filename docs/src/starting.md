# Starting with FinancialToolbox

## Example of Usage
The following example is the pricing of a European Call Option with underlying varying
according to the Black Scholes Model, given the implied volatility.
After that it is possible to check the result computing the inverse of the Black Scholes formula.
```Julia
#Import the Package
using FinancialToolbox

#Define input data
spot=10;K=10;r=0.02;T=2.0;σ=0.2;d=0.01;

#Call the function
Price=blsprice(spot,K,r,T,σ,d)
#Price=1.1912013169995816

#Check the Result
Volatility=blsimpv(spot,K,r,T,Price,d)
#Volatility=0.20000000000000002
```
