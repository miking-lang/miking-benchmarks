from torch import log, tensor
from pyro import sample, factor
from pyro.distributions import Gamma, Poisson, Exponential, Bernoulli
from numpy import log as nplog, inf, ones
from numpy.random import poisson, exponential, uniform
from numba import jit


def survives(t, λ, μ, ρ):
    Δ = exponential(1/μ)
    if Δ > t:
        if uniform(0., 1.) < ρ:
            return True
        Δ = t
    t_end = t - Δ
    for i in range(poisson(λ*Δ)):
        τ = uniform(t_end, t)
        if survives(τ, λ, μ, ρ):
            return True
    return False


def vec_survives(t_beg, t_end, count_, λ, μ, ρ):
    f = nplog(2) * count_
    for n in range(count_.size):
        for hs in range(int(count_[n])):
            t = uniform(t_end, t_beg)
            if survives(t, λ[n], μ[n], ρ):
                f[n] = -inf
                break
    return f


class CRBD:
    def init(self, state, N):
        state["λ"] = sample("λ", Gamma(1., 1./1.))
        state["μ"] = sample("μ", Gamma(1., 1./0.5))
        f = (N-1)*log(tensor(2))
        for n in range(2, N+1):
            f -= log(tensor(n))
        factor("factor_orient_labeled", f)

    def step(self, state, branch, ρ=1.0):
        Δ = branch["t_beg"] - branch["t_end"]
        if branch['parent_id'] is None and Δ < 1e-5:
            return
        count_hs = sample(f"count_hs_{branch['id']}", Poisson(state["λ"] * Δ))
        f = vec_survives(branch["t_end"], branch["t_beg"], count_hs.numpy(), state["λ"].numpy(), state["μ"].numpy(), ρ)
        factor(f"factor_hs_{branch['id']}", f)
        sample(f"num_ex_{branch['id']}", Poisson(state["μ"] * Δ), obs=tensor(0))
        if branch["has_children"]:
            sample(f"spec_{branch['id']}", Exponential(state["λ"]), obs=tensor(1e-40))
        else:
            sample(f"obs_{branch['id']}", Bernoulli(ρ), obs=tensor(1.))


class CRBDGuide:
    def init(self, state, *args, **kwargs): pass
    def step(self, state, *args, **kwargs): pass
