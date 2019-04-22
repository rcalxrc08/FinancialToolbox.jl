using Test
using FinancialToolbox,DualNumbers

#Test Parameters
testToll=1e-14;

#print_colored("Starting Standard Test\n",:green)
spot=10;K=10;r=0.02;T=2.0;sigma=0.2;d=0.01;
spotDual=dual(spot,1.0);

toll=1e-8

#EuropeanCall Option
PriceCall=blsprice(spot,K,r,T,sigma,d);
PriceCallBlack=blkprice(spot,K,r,T,sigma);

df(f,x,dx)=(f(x+dx)-f(x))/dx
dx=1e-8;
assert_(value,toll)=@assert abs(value)<toll

sigma1=blsimpv(spot, K, r, T, PriceCall, d);
ResDual=blsimpv(spotDual, K, r, T, PriceCall, d);
DerDF_=df(spot->blsimpv(spot, K, r, T, PriceCall, d),spot,dx);

assert_(sigma1-ResDual,toll)
assert_(DerDF_-ResDual.epsilon,toll)

sigma1=blkimpv(spot, K, r, T, PriceCallBlack);
ResDual=blkimpv(spotDual, K, r, T, PriceCallBlack);
DerDF_=df(spot->blkimpv(spot, K, r, T, PriceCallBlack),spot,dx);

assert_(sigma1-ResDual,toll)
assert_(DerDF_-ResDual.epsilon,toll)
