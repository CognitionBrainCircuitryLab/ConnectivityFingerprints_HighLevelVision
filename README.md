# Connectivity Fingerprints of Category-Selective Visual Cortex

Github repository to accompany "Distinct Connectivity Fingerprints Reveal Functional Specialization in High-level Visual Cortex" by Liao, Ginell & Osher (under revision).

Version 1: release of the data and code needed to reproduce the figures and tables.

The repository contains the hemisphere-combined connectivity fingerprints (final trained ridge-regression models) of 10 category-selective fROIs (OFA, FFA, STS, EBA, FBA, LO, PFS, PPA, RSC, TOS), their raw resting-state connectivity profiles, parcel-wise localizer responses, model fit and reliability estimates from 40 subjects, together with a MATLAB script that regenerates every figure and table in the paper from them.

* `visconn_data.mat` contains all data (variables listed below). The `readme` variable inside the file repeats these descriptions.
* `reproduce_visconn_results.m` loads `visconn_data.mat` and reproduces every figure and table, one section each. Requires MATLAB R2019b or later with the Statistics and Machine Learning Toolbox. The surface renderings in the last section additionally need FreeSurfer's MATLAB tools (`$FREESURFER_HOME/matlab`) and `SUBJECTS_DIR` set to a directory containing `fsaverage`; the section is skipped if they are absent.
* `DYLOC_surf_databyatlas.m` renders parcel-wise values on a FreeSurfer surface (used for the fingerprint surface maps).

All ROI dimensions use the order in `roiNames`; all parcel dimensions use the order in `parcelNames`. Left and right hemispheres are combined in every variable (mean of the two hemispheres; correlations averaged in Fisher z). `visconn_data.mat` contains the following variables:

* `roiNames` is a 10 item vector of the abbreviations for each fROI in order: OFA, FFA, STS (faces), EBA, FBA (bodies), LO, PFS (objects), PPA, RSC, TOS (scenes).
* `roiDomain` is a 10 item vector giving the preferred category of each fROI (face, body, object or scene).
* `parcelNames` is a 179 item vector of the names of the ipsilateral target regions from Glasser et al. 2016 (hippocampus excluded).
* `subjectIDs` is a 40 item vector of anonymised subject labels, in the order used by every subject dimension.
* `contrastNames` is a 4 item vector of the localizer contrasts (Faces, Bodies, Objects, Scenes; each category vs. all others).
* `fingerprintWeights` is a 179 (targets) x 10 (fROIs) matrix of the final model's β values: the connectivity fingerprint of each fROI, predicting vertex-wise localizer response in the fROI search space from vertex-to-target resting-state connectivity. The intercept and the anatomical predictors (curvature, thickness, x, y, z) are not included.
* `fingerprintSimilarity` is a 10 x 10 matrix of Pearson correlations between the fingerprints of each pair of fROIs, computed within each hemisphere and averaged.
* `rawConnectivity` is a 179 (targets) x 10 (fROIs) x 40 (subjects) array of each subject's raw resting-state connectivity profile for each fROI: the mean over the fROI vertices (top 10% of the search space by localizer response) of vertex-to-target connectivity.
* `rawConnectivitySimilarity` is a 10 x 10 matrix of Pearson correlations between the group-mean raw connectivity profiles of each pair of fROIs, computed within each hemisphere and averaged.
* `parcelResponse` is a 179 (targets) x 4 (contrasts) x 40 (subjects) array of the mean localizer contrast (z) within each target region on fsaverage.
* `fingerprintSelectivityCorr` is a 10 (fROIs) x 4 (contrasts) matrix of Pearson correlations between each fingerprint and the group-mean parcel-wise localizer contrast, computed within each hemisphere and averaged.
* `modelFit` is a 40 (subjects) x 10 (fROIs) matrix of model fit: the Pearson correlation between the final model's predicted and the observed (z-scored) localizer response across the search-space vertices of each subject.
* `runToRunCeiling` is a 10 item vector of the run-to-run reliability (r) of the localizer response within each fROI search space, the noise ceiling shown on the model-fit figure.
* `bootstrapFingerprintCorr` is a 1000 (bootstrap iterations) x 10 (fROIs) matrix of correlations between the fingerprint fit on a bootstrap resample of subjects and the full-sample fingerprint.
