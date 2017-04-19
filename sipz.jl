using Plots
period = 10

function v_target(t)
    if t % period >= period/2
        return [1, 1]
    else
        return [1, -1]
    end
end

function a_predator(t, k_r, k_v, p_r)
    if (t < 10)
        return [0,0]
    end
    return normalize(p_r - k_r) * 0.05
end

prey = []
kozai = []

p_r = [0, 0]
k_r = [0, 0]
k_v = [0, 0]

dt = 0.5
for t in 0:dt:50
    p_r += v_target(t) .* dt
    k_v += a_predator(t, k_r, k_v, p_r) .* dt
    k_r += k_v .* dt

    push!(prey, p_r)
    push!(kozai, k_r)
end

# plot(map(x -> x[1], prey), map(x -> x[2], prey))
# plot!(map(x -> x[1], kozai), map(x -> x[2], kozai))

@gif for i in 1:length(prey)
    @printf("%d\n", i)
    plot(map(x -> x[1], prey[1:i]), map(x -> x[2], prey[1:i]))
    plot!(map(x -> x[1], kozai[1:i]), map(x -> x[2], kozai[1:i]))
end every 1
