from torch import log, tensor, zeros, ones
from pyro import sample, factor
from pyro.distributions import Gamma, Exponential, Poisson, Uniform, Bernoulli


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
        if branch['parent_id'] is None and Δ == 0:
            return
        count_hs = sample(f"count_hs_{branch['id']}", Poisson(state["λ"] * Δ))
        f = zeros(state._num_particles)
        for n in range(state._num_particles):
            for i in range(int(count_hs[n])):
                t = Uniform(branch["t_end"], branch["t_beg"]).sample()
                if self.survives(t, state["λ"][n], state["μ"][n], ρ):
                    f[n] = -float('inf')
                    break
                f[n] += log(tensor(2))
        factor(f"factor_hs_{branch['id']}", f)
        sample(f"num_ex_{branch['id']}", Poisson(state["μ"] * Δ), obs=tensor(0))
        if branch["has_children"]:
            sample(f"spec_{branch['id']}", Exponential(state["λ"]), obs=tensor(1e-40))
        else:
            sample(f"obs_{branch['id']}", Bernoulli(ρ), obs=tensor(1.))

    def survives(self, t, λ, μ, ρ):
        t_end = t - Exponential(μ).sample()
        if t_end <= 0:
            if Bernoulli(ρ).sample():
                return True
            t_end = 0
        for i in range(int(Poisson(λ * (t - t_end)).sample())):
            τ = Uniform(t_end, t).sample()
            if self.survives(τ, λ, μ, ρ):
                return True
        return False


class CRBDGuide:
    def init(self, state, *args, **kwargs): pass
    def step(self, state, *args, **kwargs): pass
