# NetworkRewardGenerator (in progress)
- Find optimal reward/penalty stimulus for spiking neural networks.

## Plan
- Reproduce the model and core results in the paper _Shaping Embodied Neural Networks for Adaptive Goal-directed Behavior_ (Chao et al., 2008).
- Apply the framework of reinforcement learning to find the best strategy for delivering reward and penalty.

## About the model
### Undescribed parameters
- Connectivity: the closer two neurons are, the more likely they would connect. The probility that two neurons will be connect is linearly related with their Euclidean distance. The number of synaptic connections per neuron followed a Gaussian distribution and each neuron had 50 ± 33 (mean ± ?) synapses onto other neurons.
- Places: neurons are placed in a 3mm by 3mm area with uniform distribution  
- ODE solver: ode45  
- One stimulation electrode stimulated 76 ± 12 (n = 5 simulated networks) of the closest neurons
- An 8 × 8 grid of electrodes with 333 μm inter-electrode spacing was included. All electrodes could be used for stimulation, and 60 of these (except corner electrodes 11, 18, 81, and 88) were used for recording
