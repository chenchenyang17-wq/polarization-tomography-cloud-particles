# polarization-tomography-cloud-particles

Analysis code for polarization tomographic imaging of cloud particles, including holographic reconstruction, morphological feature extraction, polarization parameter calculation, SVM classification, and figure/table reproduction.

This repository contains the MATLAB code associated with the manuscript:

**Single-Particle Polarization Tomography Enables Highly Accurate Phase Identification of Cloud Particles**

## Repository structure

```text
polarization-tomography-cloud-particles/
├── src/
│   └── Main MATLAB source code
├── scripts/
│   └── Top-level MATLAB scripts for running the workflow and reproducing figures/tables
├── example_data/
│   └── Small example data for demonstrating code usage
├── docs/
│   └── Documentation, workflow description, and input/output notes
├── LICENSE
├── .gitignore
└── README.md

```

## Main functions

The MATLAB code in this repository is used for:

1. Holographic reconstruction of cloud-particle images
2. Particle segmentation and morphological feature extraction
3. Calculation of polarization parameters, including Stokes parameters and DoLP
4. Linear SVM classification of liquid droplets and ice crystals
5. Reproduction of selected figures and tables in the manuscript

## Software requirements

The code was developed and tested in MATLAB.

Recommended software:

- MATLAB R2021a or later
- Image Processing Toolbox
- Statistics and Machine Learning Toolbox



## Data availability

The full research dataset has been archived in Zenodo.

The dataset includes calibration measurements, extracted single-particle morphological and polarization parameters, particle labels, train/test split information, classification results, and the underlying data used to generate the figures and tables in the manuscript.

Dataset DOI: https://doi.org/10.5281/zenodo.20809317


## Software archive

Version 1.0.0 of this repository has been archived in Zenodo.

Software DOI: https://doi.org/10.5281/zenodo.20424416

## License

This software is released under the MIT License. See the `LICENSE` file for details.

## Citation

## Citation

If you use this code, please cite the associated software record:

Chen, Y., Xu, X., Xiao, R., Yao, F., Shi, X., & Wang, J. (2026). Code for "Single-Particle Polarization Tomography Enables Highly Accurate Phase Identification of Cloud Particles" (Version 1.0.0) [Software]. Zenodo. https://doi.org/10.5281/zenodo.20424416

