from torch import tensor, full, log, exp, ones, max
from pyro import sample, factor
from pyro.distributions import Beta, Binomial, Poisson, Uniform, Categorical


class YapDengue:
    def init(self, state):
        obs = lambda value: full((state._num_particles,), value)

        # state["h.ν"] = obs(0.0)
        # state["h.μ"] = obs(1.0)
        state["h.λ"] = sample("h.λ", Beta(1.0, 1.0))
        state["h.δ"] = sample("h.δ", Beta(1.0 + 2.0/4.4, 3.0 - 2.0/4.4))
        state["h.γ"] = sample("h.γ", Beta(1.0 + 2.0/4.5, 3.0 - 2.0/4.5))
        state["m.ν"] = obs(1.0/7.0)
        state["m.μ"] = obs(6.0/7.0)
        state["m.λ"] = sample("m.λ", Beta(1.0, 1.0))
        state["m.δ"] = sample("m.δ", Beta(1.0 + 2.0/6.5, 3.0 - 2.0/6.5))
        state["m.γ"] = obs(0.0)
        state["ρ"] = sample("ρ", Beta(1.0, 1.0))
        state["z"] = obs(0)

    def transfer(self, state, w, t, τ):
        # total population
        n = state[f"{w}.s{t-1}"] + state[f"{w}.e{t-1}"] + state[f"{w}.i{t-1}"] + state[f"{w}.r{t-1}"]

        # transfers
        state[f"{w}.Δe{t}"] = sample(f"{w}.Δe{t}", Binomial(τ, state[f"{w}.λ"]))
        state[f"{w}.Δi{t}"] = sample(f"{w}.Δi{t}", Binomial(state[f"{w}.e{t-1}"], state[f"{w}.δ"]))
        state[f"{w}.Δr{t}"] = sample(f"{w}.Δr{t}", Binomial(state[f"{w}.i{t-1}"], state[f"{w}.γ"]))

        state[f"{w}.s{t}"] = state[f"{w}.s{t-1}"] - state[f"{w}.Δe{t}"]
        state[f"{w}.e{t}"] = state[f"{w}.e{t-1}"] + state[f"{w}.Δe{t}"] - state[f"{w}.Δi{t}"]
        state[f"{w}.i{t}"] = state[f"{w}.i{t-1}"] + state[f"{w}.Δi{t}"] - state[f"{w}.Δr{t}"]
        state[f"{w}.r{t}"] = state[f"{w}.r{t-1}"] + state[f"{w}.Δr{t}"]

        if w != 'h':
            # survival
            state[f"{w}.s{t}"] = sample(f"{w}.s{t}", Binomial(state[f"{w}.s{t}"], state[f"{w}.μ"]))
            state[f"{w}.e{t}"] = sample(f"{w}.e{t}", Binomial(state[f"{w}.e{t}"], state[f"{w}.μ"]))
            state[f"{w}.i{t}"] = sample(f"{w}.i{t}", Binomial(state[f"{w}.i{t}"], state[f"{w}.μ"]))
            state[f"{w}.r{t}"] = sample(f"{w}.r{t}", Binomial(state[f"{w}.r{t}"], state[f"{w}.μ"]))

            # births
            state[f"{w}.Δs{t}"] = sample(f"{w}.Δs{t}", Binomial(n, state[f"{w}.ν"]))
            state[f"{w}.s{t}"] = state[f"{w}.s{t}"] + state[f"{w}.Δs{t}"]

    def step(self, state, t, y):
        obs = lambda value: full((state._num_particles,), value)

        if t == 0:
            # initial state
            n = 7370
            state[f"h.i{t}"] = sample(f"h.i{t}", Poisson(5.0))
            state[f"h.i{t}"] = state[f"h.i{t}"] + 1
            state[f"h.e{t}"] = sample(f"h.e{t}", Poisson(5.0))

            max_val = n - state[f"h.i{t}"] - state[f"h.e{t}"]
            probs = ones((max_val.shape[0], 1+int(max_val.max()))).cumsum(1) <= 1 + max_val.reshape(-1, 1)
            state[f"h.r{t}"] = sample(f"h.r{t}", Categorical(probs=probs))
            state[f"h.s{t}"] = n - state[f"h.e{t}"] - state[f"h.i{t}"] - state[f"h.r{t}"]

            state[f"h.Δs{t}"] = obs(0)
            state[f"h.Δe{t}"] = state[f"h.e{t}"]
            state[f"h.Δi{t}"] = state[f"h.i{t}"]
            state[f"h.Δr{t}"] = obs(0)

            u = sample("u{t}", Uniform(-1.0, 2.0))
            state[f"m.s{t}"] = n*pow(10.0, u).int()
            state[f"m.e{t}"] = obs(0)
            state[f"m.i{t}"] = obs(0)
            state[f"m.r{t}"] = obs(0)

            state[f"m.Δs{t}"] = obs(0)
            state[f"m.Δe{t}"] = obs(0)
            state[f"m.Δi{t}"] = obs(0)
            state[f"m.Δr{t}"] = obs(0)
        else:
            n = state[f"h.s{t-1}"] + state[f"h.e{t-1}"] + state[f"h.i{t-1}"] + state[f"h.r{t-1}"]

            # transition of human population
            τ_h = sample(f"τ_h{t}", Binomial(state[f"h.s{t-1}"], 1.0 - exp(-state[f"m.i{t-1}"]/n)))
            self.transfer(state, "h", t, τ_h)

            # transition of mosquito population
            τ_m = sample(f"τ_m{t}", Binomial(state[f"m.s{t-1}"], 1.0 - exp(-state[f"h.i{t-1}"]/n)))
            self.transfer(state, "m", t, τ_m)

        # observation
        state["z"] = state["z"] + state[f"h.Δi{t}"]
        if y is not None:
            factor("ytest{t}", log(state["z"] >= y))
            sample(f"y{t}", Binomial(max(state["z"], tensor(y)), state["ρ"]), obs=obs(y))
            state["z"] = obs(0)


class YapDengueGuide:
    def init(self, state, *args, **kwargs): pass
    def step(self, state, *args, **kwargs): pass
