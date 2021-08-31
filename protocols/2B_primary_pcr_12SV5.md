# Protocol 2B: Primary qPCR (12SV5)

## Materials
- [ ] 2X AccuStart II PCR SuperMix (95137-100, 95137-500, or 95137-04K)
- [ ] 10µM working stock of 12SV5 forward primer with Illumina bridges (BP039)
- [ ] 10µM working stock of 12SV5 reverse primer with Illumina bridges (BP040)
- [ ] 100µM working stock of human blocking primer (BP102)
- [ ] 20 ug/uL working stock of bovine serum albumin (BSA) (B14)
- [ ] SYBR Green I - diluted in DMSO to 100x
- [ ] gDNA from [Protocol 1: DNA extraction](https://github.com/bpetrone/mb-pipeline/blob/master/protocols/1_dna_extraction.md) or other source in a 96 well plate
- [ ] Positive control template DNA
- [ ] Nuclease-free H<sub>2</sub>O

## Protocol
**Location:** PCR hood or separate room/area from other steps.
- [ ] Treat PCR area with UV light for ~15 minutes.
- [ ] Generate enough PCR master mix for the reactions desired according to **Table 1**. Note: The reaction mix and plate must be kept on ice; otherwise, the exonuclease in the enzyme can degrade the primers prior to the start of the reaction. Leave the polymerase in the freezer until use.
- [ ] Aliquot 9 µl mix into each well.
- [ ] Add 1 ul water to negative control well.
- [ ] Add 1 µl of DNA template to sample wells.
- [ ] Add 1 ul control DNA to positive control well.
- [ ] Seal plate with optical film.
- [ ] Briefly spin down the plate (30 seconds at 1K rpm in bench-top centrifuge).  
- [ ] Run qPCR with cycling conditions from **Table 2**.
- [ ] After qPCR run is done, transfer plates to -20˚C if processing is going to be paused.  Otherwise, keep plates at 4˚C.  
- [ ] Inspect qPCR curves to confirm amplification and/or run 5 ul on an agarose gel or E-gel to confirm a single band of expected size.
- [ ] Proceed to [Protocol 3: Dilution](https://github.com/bpetrone/mb-pipeline/edit/master/protocols/3_dilution.md)

**Table 1. Primary PCR Master Mix**
Component	| 1 Rxn (µL) | 100 Rxns (µL) 
----------|------------|--------------
Nuclease-free H_2O	| 1.65 | 165
10 µM Forward primer	| 0.5	| 50
10 µM Reverse primer	| 0.5	| 50
100 µM blocking primer	| 1.0	| 100
100x SYBR Green	| 0.1	| 10
2X AccuStart	| 5.0	| 500
**Total**	| **9.0**	| **900**

**Table 2. Primary PCR Amplification Parameters**
Cycle |	Temperature (˚C)  | Time
------|-------------------|------
Initial Denaturation   |	94	| 3 min
35 cycles:
Denature | 94˚C | 20 sec
Anneal | 57˚C	| 15 sec
Extend | 72˚C | 1 min
Holding	| 4˚C	Hold | For ever
