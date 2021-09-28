from torch import full, exp
from pyro import sample
from pyro.distributions import Gamma, Beta, Binomial, Delta


class SIR:
    def init(self, state, λ, s0, i0, r0):
        obs = lambda value: full((state._num_particles,), value)

        state["λ"] = sample("λ", Gamma(2., 1./5.0), obs=obs(λ))
        state["δ"] = sample("δ", Beta(2., 2.))
        state["γ"] = sample("γ", Beta(2., 2.))

        state["s0"] = obs(s0)
        state["i0"] = obs(i0)
        state["r0"] = obs(r0)

    def step(self, state, t, i):
        obs = lambda value: full((state._num_particles,), value)

        n = state[f"s{t-1}"] + state[f"i{t-1}"] + state[f"r{t-1}"]
        τ = sample(f"τ{t}", Binomial(state[f"s{t-1}"], 1.0 - exp(-state["λ"]*state[f"i{t-1}"]/n)))
        Δi = sample(f"Δi{t}", Binomial(τ, state["δ"]))
        Δr = sample(f"Δr{t}", Binomial(state[f"i{t-1}"], state["γ"]))
        state[f"s{t}"] = sample(f"s{t}", Delta(state[f"s{t-1}"] - Δi))
        state[f"i{t}"] = sample(f"i{t}", Delta(state[f"i{t-1}"] + Δi - Δr), obs=obs(i))
        state[f"r{t}"] = sample(f"r{t}", Delta(state[f"r{t-1}"] + Δr))


class SIRGuide:
    def init(self, state, *args, **kwargs): pass
    def step(self, state, *args, **kwargs): pass
