using Plots
# The GR plotting background is significantly faster
gr();

function v_target(t)
    return [1, sin(t*2*pi/10)]
    
    # This codes for a zigzag with period 10
    if t % 10 >= 10/2
        return [1, 1]
    else
        return [1, -1]
    end
end

function a_predator(t, k_r, p_r, k_m)
    # Acceleration is directed directly at the prey, and is scaled by the mass
    return normalize(p_r - k_r)/k_m
end

function mass_to_period(kozai_masses)
    # Euler's Method time resolution
    dt = 0.5
    time_max=1000000

    # Preallocate giant arrays and use them repeatedly for speed
    print("Allocating memory...")
    flush(STDOUT)
    kozai = zeros(Int(time_max/dt+1),2)
    y_s = zeros(time_max)
    results = []
    print(" done.\n")
    flush(STDOUT)
    
    for kozai_mass in kozai_masses
        # Set initial conditions
        p_r = [0, 0]
        k_r = [0, 0]
        k_v = [0, 0]
        
        # This is just a fairly general Euler's Method solver for parametric DEs
        for (index, t) in enumerate(0:dt:time_max)
            p_r += v_target(t) .* dt
            k_v += a_predator(t, k_r, p_r, kozai_mass) .* dt

            if norm(k_v) != 0
                k_v = normalize(k_v) .* min(norm(k_v))
            end

            k_r += k_v .* dt

            kozai[index,:] = k_r
        end
        
        # Now we "flatten" the parametric position array [(x, y)...]
        # into a x vs. y array [y1, y2 ...]
        # NOTE: This only makes sense when the parametric curve passes
        # the vertical line test, which, in many cases, it does not.
        fill(y_s, 0)
        for i in 1:size(kozai,1)
            (x, y) = kozai[i,:]
            if ceil(Int, x) > time_max
                # If, as happens by chance, the prey passes max_time,
                # truncate to fit.
                continue
            end
            y_s[ceil(Int, x)] = round(Int,y)
        end
        
        # Make sure the trajectory is centered around zero so the signal is clean
        y_s -= mean(y_s)
        
        # Now convert to frequency space using a Fast Fourier Transform
        # Lots of random constants floating around to make the frequency mappings work.
        dT = 1 # This is 1 because we are working in index space
        yf = 2.0/(time_max/dT) * abs(rfft(y_s))
        xf = linspace(0, 0.5/dT, div(time_max/dT,2))
        
        # A heuristic to extract the "low" frequency modulation. Essentially, 
        # we find the strongest signal, which is the  "high" frequency 
        # oscillation and look for a peak at less than half its frequency.
        period = 1/xf[indmax(yf[10:div(indmax(yf),2)])+9]
        push!(results, period)
        
        @printf("%d\r", kozai_mass)
        flush(STDOUT)
    end
    results
end

function polyfit(x, y, n)
    # Really simple polynomial least-squares fit
    A = [ float(x[i])^p for i = 1:length(x), p = 0:n ]
    A \ y
end

function model(coeff)
    # Produce a model closure from the polyfit output
    function result(x)
        reduce(+, (c*x^(p-1) for (p, c) in enumerate(coeff)))
    end
end;

X = 40:1:300
periods = mass_to_period(X);

plot(X, periods)
fit = polyfit(X, periods,2)
plot!(X, map(model(fit), X))

# plot residuals
plot(X, periods - map(model(fit), X))
