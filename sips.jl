addprocs(4)
import DifferentialEquations
import ParameterizedFunctions
@everywhere using DifferentialEquations
@everywhere using ParameterizedFunctions
using Plots
using LsqFit
using ProgressMeter
using PmapProgressMeter
gr();

# DE system representing our model
@everywhere de_system = @ode_def_noinvjac Sips2 begin
    dpx = 1
    dpy = 2*pi*sin(2*pi*t/5)
    dkx = kvx
    dky = kvy
    # We add a very small float value to the denominator so we never divide by zero
    dkvx = (px - kx)/sqrt((px - kx)^2 + (py - ky)^2+0.00000000001)/m
    dkvy = (py - ky)/sqrt((px - kx)^2 + (py - ky)^2+0.00000000001)/m
end m=>1.0

function mass_to_period(kozai_masses)
    # Euler's Method time resolution
    pmap(
        function (kozai_mass)
            time_max=1000000
            # Set initial conditions
            u0 = [0.0; 0.0; 0.0; 0.0; 0.0; 0.0]
            de_system.m = kozai_mass
            tspan = (0.0, 1.0*time_max)

            # Solve using Hairer's 8/5/3 adaption of the Dormand-Prince 8 Runge-Kutta method. 
            # (7th order interpolant)
            # Oddly, we need a super high-order interpolant, otherwise our
            # cumulative errors get out of hand. Vern9 was the only method that 
            # could solve this system with high accuracy in reaonable time
            prob = ODEProblem(de_system, u0, tspan)
            sol = solve(prob, Vern9())

            # Now we "flatten" the parametric position array [[..., x, y, ...]...]
            # into a index vs. y array [y1, y2 ...]. We do this so we can later
            # pass the array to the DFT, which takes a glat array as input.
            # NOTE: We don't perform any scaling. index <==> x
            # NOTE: This only makes sense when the parametric curve passes
            # the vertical line test, which, in many cases, it does not.
            wave_function = zeros(time_max)
            for t in linspace(0, time_max, time_max * 2)
                (px, py, x, y, vx, vy) = sol(t)
                wave_function[min(round(Int, x)+1,end)] = y
            end

            # Make sure the trajectory is centered around zero.
            # Otherwise, the FFT will produce a mess trying to build
            # a constant out of sines. 
            #wave_function -= mean(wave_function)

            # Now convert to frequency space using a Fast Fourier Transform
            # Lots of random constants floating around to make the frequency mappings work,
            # since the real-valued FFT only returns an array of half size
            dT = 1 # This is 1 because we are working in index space
            yf = 2.0/(time_max/dT) * abs(rfft(wave_function))
            xf = linspace(0, 0.5/dT, div(time_max/dT,2))
            #1/xf[findmax(yf[10:div(findmax(yf)[2],2)])[2]]

            # A heuristic to extract the "low" frequency oscillation. Essentially, 
            # we find the strongest signal, which is the  "high" frequency 
            # oscillation and look for a peak at less than half that frequency.
            fast_idx = indmax(yf[10:end])+9
            fast_period = 1/xf[fast_idx]
            slow_idx = indmax(yf[10:div(fast_idx, 2)])+9
            slow_period = 1/xf[slow_idx]

            (slow_period, fast_period)
        end,
        Progress(length(kozai_masses)),
        kozai_masses
    )
end;

# Compute the periods for a varying set of masses
X = linspace(50, 450, 150)
periods = mass_to_period(X)

# For now, examine slow periods
X = map(x -> x[1], X)

# Fit a quadratic model to the data
quad(x, p) = p[1] + p[2].*x + p[3].*x.^2
fit = curve_fit(quad, X, periods, [0.0,0.0,0.0])

plot(X, periods)
plot!(X, map(x -> quad(x, fit.param), X))
xaxis!("Mass")
yaxis!("Long-range period")
title!("Period vs. Mass")

(fit.param, estimate_errors(fit,0.95))
