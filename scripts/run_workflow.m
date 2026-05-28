%% run_workflow.m
% Workflow template for the MATLAB code used in:
% "Single-Particle Polarization Tomography Enables Highly Accurate Phase Identification of Cloud Particles"
%
% Processing workflow:
% 1. Holographic reconstruction of polarization images
% 2. DoLP calculation from reconstructed polarization images
% 3. Holographic reconstruction of original intensity images
% 4. Microphysical parameter extraction from reconstructed original images
% 5. SVM classification using circularity and DoLP

clear; clc;

%% Add source code paths
addpath(genpath('../src'));

%% Step 1: Holographic reconstruction of polarization images
% This step reconstructs polarization-resolved holographic images.
% The reconstructed images are used for Stokes parameter and DoLP calculation.
%
% Main code:
% src/reconstruction/zaixianchengxu_aa1.m
%
% Uncomment and modify input/output paths before running:
% run('../src/reconstruction/zaixianchengxu_aa1.m');

%% Step 2: DoLP calculation
% This step calculates Stokes parameters and the degree of linear polarization
% from reconstructed polarization images.
%
% Main code:
% src/polarization/DOLPAOPX.m
%
% Expected outputs may include:
% S0, S1, S2, DoLP, particle_id, frame_id, and particle position information.
%
% Uncomment and modify input/output paths before running:
% run('../src/polarization/DOLPAOPX.m');

%% Step 3: Holographic reconstruction of original intensity images
% This step reconstructs the original particle images to determine the
% in-focus plane and intensity distribution for morphological analysis.
%
% Main code:
% src/reconstruction/zaixianchengxu_aa1.m
%
% If the same reconstruction code is used for both polarization images and
% original images, modify the input path inside the reconstruction script.
%
% Uncomment and modify input/output paths before running:
% run('../src/reconstruction/zaixianchengxu_aa1.m');

%% Step 4: Microphysical parameter extraction
% This step extracts particle morphological and microphysical parameters
% from the reconstructed original images.
%
% Main code:
% src/microphysics/main_zi.m
%
% Supporting functions may include:
% RemoveDuplicateParticals4.m
% RemoveSmallParticles.m
% hhhh.m
% minboundrect.m
% minboxing.m
% mix_a7.m
% zaixianchengxu_aa0.m
%
% Expected outputs may include:
% particle_id, x, y, z, equivalent diameter, area, perimeter,
% major axis, minor axis, and circularity.
%
% Uncomment and modify input/output paths before running:
% run('../src/microphysics/main_zi.m');

%% Step 5: Merge DoLP and microphysical parameters
% Before SVM classification, merge the polarization features and
% microphysical features for the same particles.
%
% Final feature table should include at least:
% particle_id
% circularity
% DoLP
% true_label
%
% This merged table is used as input for SVM classification.

%% Step 6: SVM classification
% This step classifies liquid droplets and ice crystals using circularity
% and DoLP as input features.
%
% Main code:
% src/classification/xxSVM.m
%
% Uncomment and modify input/output paths before running:
% run('../src/classification/xxSVM.m');

disp('Workflow template loaded. Please modify data paths before running each module.');
