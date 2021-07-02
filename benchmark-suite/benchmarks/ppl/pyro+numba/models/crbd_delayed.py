from torch import log, tensor, full
from pyro import sample, factor
from pyro.distributions import GammaPoisson, Bernoulli
from numpy import log as nplog, inf, ones
from numpy.random import pareto, negative_binomial, uniform
from numba import jit, prange


@jit(cache=True)
def survives(t, λ_α, λ_β, μ_α, μ_β, ρ):
    Δ = pareto(μ_α[0]) * μ_β[0]
    μ_α += 1
    μ_β += Δ
    if Δ > t:
        if uniform(0., 1.) < ρ:
            return True
        Δ = t
    t_end = t - Δ
    s = negative_binomial(λ_α[0], λ_β[0]/(λ_β[0] + Δ))
    λ_α += s
    λ_β += Δ
    for i in range(s):
        τ = uniform(t_end, t)
        if survives(τ, λ_α, λ_β, μ_α, μ_β, ρ):
            return True
    return False


@jit(cache=True, parallel=True)
def vec_survives(t_beg, t_end, count_, λ_α, λ_β, μ_α, μ_β, ρ):
    f = nplog(2) * count_
    for n in prange(count_.size):
        for hs in range(int(count_[n])):
            t = uniform(t_end, t_beg)
            if survives(t, λ_α[n:n+1], λ_β[n:n+1], μ_α[n:n+1], μ_β[n:n+1], ρ):
                f[n] = -inf
                break
    return f


class CRBD:
    def init(self, state, N):
        state["λ_α"] = full((state._num_particles,), 1.)
        state["λ_β"] = full((state._num_particles,), 1./1.)
        state["μ_α"] = full((state._num_particles,), 1.)
        state["μ_β"] = full((state._num_particles,), 1./0.5)
        f = (N-1)*log(tensor(2))
        for n in range(2, N+1):
            f -= log(tensor(n))
        factor("factor_orient_labeled", f)

    def step(self, state, branch, ρ=1.0):
        Δ = branch["t_beg"] - branch["t_end"]
        if branch['parent_id'] is None and Δ < 1e-5:
            return
        count_hs = sample(f"count_hs_{branch['id']}", GammaPoisson(state["λ_α"], state["λ_β"]/Δ))
        state["λ_α"] += count_hs
        state["λ_β"] += Δ
        f = vec_survives(branch["t_end"], branch["t_beg"], count_hs.numpy(),
            state["λ_α"].numpy(), state["λ_β"].numpy(), state["μ_α"].numpy(), state["μ_β"].numpy(), ρ)
        factor(f"factor_hs_{branch['id']}", f)
        sample(f"num_ex_{branch['id']}", GammaPoisson(state["μ_α"], state["μ_β"]/Δ), obs=tensor(0))
        state["μ_β"] += Δ
        if branch["has_children"]:
            factor(f"spec_{branch['id']}", log(state["λ_α"]) - log(state["λ_β"]))
            state["λ_α"] += 1
        else:
            sample(f"obs_{branch['id']}", Bernoulli(ρ), obs=tensor(1.))


class CRBDGuide:
    def init(self, state, *args, **kwargs): pass
    def step(self, state, *args, **kwargs): pass
