using Test
using FinancialToolbox, JSON
file_bin = read("impvres.json");
loaded_obj = JSON.parse(file_bin, allownan = true)
inputs = loaded_obj["input"]
outputs = loaded_obj["output"]
N = length(inputs);
toll = 1e-12
toll_vol = 1e-6
counter_el = 0
for i = 1:N
    r = 0.0
    cur_el = inputs[i]
    F = cur_el["F"]
    T = cur_el["T"]
    K = cur_el["K"]
    sigma = cur_el["sigma"]
    expected_res = outputs[i]["black"]
    q = cur_el["q"]
    iscall = q > 0
    price_internal = 0.0
    if F != 0.0 && T != 0.0 && K != 0.0 && sigma != 0.0
        price_internal = blkprice(F, K, r, T, sigma, iscall)
        @test abs(price_internal - expected_res) < toll
        xtol = eps(zero(Float64))
        n_iter = 5
        sigma_computed = blkimpv(F, K, r, T, price_internal, iscall, xtol, n_iter)
        price_internal2 = blkprice(F, K, r, T, sigma, !iscall)
        sigma_computed2 = 0.0
        if price_internal2 != 0.0
            sigma_computed2 = blkimpv(F, K, r, T, price_internal2, !iscall, xtol, n_iter)
        end

        if abs(sigma_computed - sigma) > toll_vol && abs(sigma_computed2 - sigma) > toll_vol
            #This is the last trial, we switch to BigFloats to try to achieve the result
            sigma_big = big(sigma)
            price_internal = blkprice(F, K, r, T, sigma_big, iscall)
            sigma_computed = blkimpv(F, K, r, T, price_internal, iscall, xtol, n_iter)
            price_internal2 = blkprice(F, K, r, T, sigma_big, !iscall)
            sigma_computed2 = 0.0
            if price_internal2 != 0.0
                sigma_computed2 = blkimpv(F, K, r, T, price_internal2, !iscall, xtol, n_iter)
            end
            if abs(sigma_computed - sigma) > toll_vol && abs(sigma_computed2 - sigma) > toll_vol
                @show F, K, T, iscall, sigma, sigma_computed, sigma_computed2
                global counter_el += 1
            end
        end
    end
end
println("counter : ", counter_el)
