# CSED273_Final_Proj
#### Implementing CORDIC Algorithm to calculate sine and cosine
---
## Progress
- [x] Implement basic operations ( <<, x10, +(-), &)

- [x] Implement testbench for basic operations ...**DEBUGGING**

- [x] Implement CORDIC algorithm to `cordic.v` file

- [ ] Implement testbench of CORDIC algorithm 

## Others
* (Jun 01) Multiplication algorithm debugged

## Todo
* Debug Multiplier as 32bit multipliers with given format :

> `S0123456789012345678901234567890`
>
> MSB S [31] is a sign bit: 0 is positive and 1 is negative
> From MSB to LSB (in order [30:0]): Each  $i$-th bit represents $2^{-(30-i)}$ is included or not.
