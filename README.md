# Microprocessors – Digital Circuit Simulation & Power Estimation Labs

Laboratory exercises for the **Microprocessors** course at the Department of Computer Science and Engineering, **University of Ioannina** (Instructor: V. Tenentes), implemented in **MATLAB / GNU Octave**[cite: 1, 11, 12].

The repository covers combinational logic simulation[cite: 1, 10, 13], analytical signal probability calculation[cite: 5, 6, 7], topological sorting of circuit netlists[cite: 8], switching activity ($E_{sw}$) estimation for dynamic power analysis[cite: 2, 10], and worst-case stress-test generation using Monte Carlo methods and Genetic Algorithms[cite: 11, 12].

---

## Repository Structure

### `Lab1_MonteCarlo_BasicGates/`
* **`MCpi.m`**: Approximates $\pi$ via Monte Carlo simulation using $N = 10,000$ random points inside a unit square and measures execution time[cite: 4].
* **`MCAND4.m` & `MCOR4.m`**: Estimate the switching activity of 4-input `AND` and `OR` gates over random binary workloads[cite: 2, 3].
* **`Circuit.m` & `Circuit_2.m`**: Perform exhaustive truth-table simulations for $d = (a \text{ AND } b) \text{ OR NOT}(c)$ and $d = (a \text{ AND } b) \text{ AND NOT}(c)$[cite: 1, 13].
* **`CircuitSA.m`**: Computes theoretical signal probabilities and switching activities ($\alpha = P(1 - P)$) for $d = (a \text{ AND } b) \text{ AND NOT}(c)$ assuming $P = 0.5$ primary inputs[cite: 14].
* **`MCCircuit.m`**: Validates theoretical signal probabilities ($P(d=1) = 0.1250$) and switching activities against empirical Monte Carlo simulations across increasing pattern counts[cite: 16].

### `Lab2_SignalProbabilities/`
* **`signalprobs.m`**: Implements analytical output signal probability functions for 2-input `AND`, `OR`, `XOR`, `NAND`, and `NOR` gates[cite: 5].
* **`signalprobs3.m`**: Extends signal probability calculations to 3-input logic gates[cite: 6].
* **`signalprobsN.m`**: Generalizes signal probability formulas to $N$-input gates using variable-length argument lists (`varargin`)[cite: 7].

### `Lab3_CircuitSimulation_TopoSort/`
* **`exe3_1.m`**: Models a combinational circuit structurally (`ElementsTable`, `SignalsTable`) and compares exhaustive truth-table $E_{sw}$ against probabilistic propagation ($E_{sw} = 2p(1-p)$)[cite: 10].
* **`exe3_2.m`**: Adds a netlist parser (`parse_circuit_file`) with both explicit (`top_inputs`) and automatic primary input detection (`detect_top_inputs_decl_or_auto`)[cite: 9].
* **`exe3_3.m`**: Integrates Kahn's topological sorting algorithm (`topo_sort`) to evaluate circuit netlists written in arbitrary gate order (`circuit_unsorted.txt`)[cite: 8].

### `Lab4_StressTests_GA/`
* **`exe4_1.m`**: Loads `Lab4_circuit.txt`, computes gate propagation delays, and evaluates $N = 2,000$ random input vector pairs ($L = 2$) to measure internal signal transitions[cite: 12].
* **`exe4_2.m`**: Uses a Genetic Algorithm (population $N = 30$, $100$ generations, mutation rate $m = 0.05$) to evolve input vector pairs that maximize worst-case switching activity.
* **`Lab4_circuit.txt`**: Input netlist file required to run `exe4_1.m` and `exe4_2.m`[cite: 11, 12].

---

## Prerequisites & Usage

1. Install **GNU Octave** or **MATLAB**[cite: 1, 16].
2. Navigate to the desired lab folder and run the scripts directly from the command window:

```matlab
% Lab 1 examples
MCAND4(1000)
MCCircuit()

% Lab 2 examples
signalprobs(0.5, 0.5)
signalprobsN(0.2, 0.5, 0.8, 0.4)

% Lab 3 & Lab 4 scripts
exe3_3
exe4_1
exe4_2
