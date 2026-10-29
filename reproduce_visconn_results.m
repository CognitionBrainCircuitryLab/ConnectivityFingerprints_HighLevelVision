% reproduce_visconn_results.m
%
% Reproduces the results and figures of
%   "Distinct Connectivity Fingerprints Reveal Functional Specialization in High-level Visual Cortex"
% from visconn_data.mat (built by export_visconn_data.m). No other input is needed.
%
% Requirements: MATLAB R2019b or later with the Statistics and Machine Learning Toolbox.
% Optional:     DYLOC_surf_databyatlas + subtightplot + FreeSurfer fsaverage, for the surface
%               renderings in the last section (skipped if absent).
%
% All variables are hemisphere-combined. ROI order everywhere:
%   OFA FFA STS | EBA FBA | LO PFS | PPA RSC TOS   (faces | bodies | objects | scenes)
% Run the whole script (a few minutes; the permutation tests dominate) or one section at a time.

clear; close all
D = load('visconn_data.mat');
disp(D.readme.overview)

nSub = numel(D.subjectIDs);                   % 40
nROI = numel(D.roiNames);                     % 10
domains   = {'face','body','object','scene'};
labels    = cellfun(@(d) find(strcmp(domains, d)), D.roiDomain);   % domain code per fROI
roiLabels = D.roiNames;

red = [0.9843 0.1020 0.0941]; green = [0.5216 0.7882 0.3020];
yellow = [0.9843 0.7353 0.1647]; blue = [0.1510 0.6510 0.9216];
domainColors = [red; red; red; green; green; yellow; yellow; blue; blue; blue];
set(groot, 'defaultFigureColor', 'w')

%% 1. Model fit per fROI  (figure: modelfit)
zFit    = atanh(D.modelFit);                  % Fisher z, nSub x 10
fitMean = tanh(mean(zFit));
fitSE   = tanh(std(zFit) / sqrt(nSub));
fprintf('Overall model fit r = %.3f\n', tanh(mean(zFit(:))));

figure('Name', 'Model fit', 'Renderer', 'painters'); hold on
b = bar(fitMean, 'FaceColor', 'flat', 'EdgeColor', 'k', 'LineWidth', 1); b.CData = domainColors;
errorbar(1:nROI, fitMean, fitSE, 'k', 'LineStyle', 'none', 'CapSize', 8, 'LineWidth', 1.2);
for i = 1:nROI                                % run-to-run reliability ceiling
    plot([i-0.4 i+0.4], D.runToRunCeiling(i) * [1 1], 'k--', 'LineWidth', 1.8);
end
set(gca, 'XTick', 1:nROI, 'XTickLabel', roiLabels, 'XTickLabelRotation', 45, 'LineWidth', 1, 'FontSize', 12)
ylabel('Model fit (r)'); ylim([0 1]); box off; hold off

%% 2. Similarity of connectivity fingerprints  (figures: lhrhcorr, lhrhdendrogram)
plotSimilarity(D.fingerprintSimilarity, roiLabels, [-0.4 0.4], 'Fingerprint similarity');
plotDendrogram(D.fingerprintSimilarity, roiLabels, 'Fingerprint clustering');

%% 3. Fingerprints vs. parcel-wise functional selectivity  (figure: lhrhfunc)
plotHeatmap(D.fingerprintSelectivityCorr, D.contrastNames, roiLabels, [-0.6 0.6], 'Fingerprint vs. selectivity');

%% 4. Similarity of raw FC profiles  (figures: lhrhconncorr_grouplevel, lhrhdendrogram_conn)
plotSimilarity(D.rawConnectivitySimilarity, roiLabels, [-0.1 1], 'Raw FC similarity');
plotDendrogram(D.rawConnectivitySimilarity, roiLabels, 'Raw FC clustering');

%% 5. Fingerprint reliability  (table: bootstrap resamples of subjects vs. the full-sample fingerprint)
rBoot = D.bootstrapFingerprintCorr;
disp(table(roiLabels(:), mean(rBoot)', std(rBoot)', 'VariableNames', {'ROI', 'BootstrapMeanR', 'SD'}))

% 6. Fingerprint surface maps  (figures: facesurfraw, bodysurfraw, objectsurfraw, scenesurfraw)
% Fingerprints z-scored across parcels, rendered on the fsaverage right hemisphere (lateral, medial,
% ventral), one figure per domain. Needs DYLOC_surf_databyatlas.m (included), FreeSurfer's MATLAB
% tools and SUBJECTS_DIR pointing at a directory containing fsaverage. The values are per Glasser
% parcel (D.parcelNames) and can also be rendered in any surface viewer.
zFingerprints = zscore(D.fingerprintWeights);                      % 179 x 10

if exist('read_annotation', 'file') && isfolder(fullfile(getenv('SUBJECTS_DIR'), 'fsaverage'))
    views = {'lateral', 'medial', 'ventral'};
    for d = 1:numel(domains)
        idx = find(labels == d);
        figure('Name', [domains{d} ' fingerprints'], 'Renderer', 'painters');
        tiledlayout(numel(views), 3, 'TileSpacing', 'none', 'Padding', 'tight');
        for vi = 1:numel(views)
            for j = 1:numel(idx)
                nexttile((vi-1)*3 + j);
                DYLOC_surf_databyatlas('glasser', D.parcelNames, 'fsaverage', ...
                    zFingerprints(:, idx(j)), 'rh', views{vi});
            end
        end
    end
else
    disp('FreeSurfer MATLAB tools or SUBJECTS_DIR/fsaverage not found: surface renderings skipped.')
end

%% ------------------------------------------------------------------ local functions
function plotHeatmap(M, xNames, yNames, clim, ttl)
figure('Name', ttl, 'Renderer', 'painters');
h = heatmap(M, 'MissingDataColor', 'k', 'GridVisible', 'off', 'MissingDataLabel', ' ', 'CellLabelFormat', '%.2f');
h.XData = xNames; h.YData = yNames; h.Title = ttl; h.ColorLimits = clim; h.Colormap = parula;
end

function plotSimilarity(M, names, clim, ttl)
plotHeatmap(M, names, names, clim, ttl)
end

function plotDendrogram(M, names, ttl)
% Average-linkage hierarchical clustering on the dissimilarity 1 - r.
Dm = 1 - (M + M') / 2; Dm(1:size(Dm, 1)+1:end) = 0;
Z = linkage(squareform(Dm, 'tovector'), 'average');
figure('Name', ttl, 'Renderer', 'painters');
h = dendrogram(Z, 'Labels', names);
set(h, 'LineWidth', 2, 'Color', 'k'); set(gca, 'LineWidth', 1); title(ttl)
end