# NetworkRewardGenerator (in progress)
- Find optimal reward/penalty stimulus for spiking neural networks.

## Plan
- Reproduce the model and core results in the paper _Shaping Embodied Neural Networks for Adaptive Goal-directed Behavior_ (Chao et al., 2008).
- Apply the framework of reinforcement learning to find the best strategy for delivering reward and penalty.

## About the model
### Undescribed parameters
- Connectivity: the closer two neurons are, the more likely they would connect. The probility that two neurons will be connect is exponentially related with their Euclidean distance. The number of synaptic connections per neuron followed a Gaussian distribution and each neuron had 50 ± 15 (mean ± std) synapses onto other neurons.
- Places: neurons are placed in a 3mm by 3mm area with uniform distribution  
- One stimulation electrode stimulated 76 of the closest neurons
- An 8 × 8 grid of electrodes with 333 μm inter-electrode spacing was included. All electrodes could be used for stimulation and recording.
