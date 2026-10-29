function DYLOC_surf_databyatlas(segname, targets, surfsub, data, hemi, surfview, crange, surfname)
% DYLOC_surf_databyatlas  Render parcel-wise data on a FreeSurfer surface into the current axes.
%
%   DYLOC_surf_databyatlas(segname, targets, surfsub, data, hemi, surfview, [crange], [surfname])
%
%   segname   annotation name: SUBJECTS_DIR/<surfsub>/label/<hemi>.<segname>.annot (e.g. 'glasser')
%   targets   cellstr of parcel names, in the same order as data (names as in the annotation)
%   surfsub   FreeSurfer subject whose surface is drawn (e.g. 'fsaverage')
%   data      one value per parcel
%   hemi      'lh' or 'rh'
%   surfview  'lateral', 'medial', 'ventral' or 'dorsal'
%   crange    [low high] colour range in absolute value; |values| below low are left grey.
%             Default [eps 0.9*max(abs(data))]. A scalar sets low only.
%   surfname  surface to draw: 'inflated' (default), 'pial', 'white', ...
%
%   Positive values are drawn red (low) to yellow (high), negative values blue to cyan, on a
%   curvature-shaded grey surface with parcel boundaries in black. Draws into the current axes
%   with no figure or colorbar call, so it tiles with tiledlayout/nexttile or subplot.
%   Needs FreeSurfer's MATLAB tools (read_annotation, freesurfer_read_surf, read_curv) and the
%   SUBJECTS_DIR environment variable.

if ~iscellstr(targets)
    error('targets must be a cell array of parcel names')
end
if nargin < 8 || isempty(surfname), surfname = 'inflated'; end
if nargin < 7 || isempty(crange),   crange = [eps 0.9*max(abs(data))]; end
if isscalar(crange),                crange = [crange 0.9*max(abs(data))]; end
if numel(crange) ~= 2, error('crange must be a 2-element vector'); end
crange = sort(crange);
data = reshape(data, 1, []);

%% Surface, curvature and parcellation
fsdir = fullfile(getenv('SUBJECTS_DIR'), surfsub);
[~, aparc, table] = read_annotation(fullfile(fsdir, 'label', [hemi '.' segname '.annot']), 0);
[vertices, faces] = freesurfer_read_surf(fullfile(fsdir, 'surf', [hemi '.' surfname]));
curv = read_curv(fullfile(fsdir, 'surf', [hemi '.curv']));

% Vertices on parcel boundaries (faces that straddle two parcels), drawn black
boundary = [];
for iParc = unique(aparc)'
    parcfaces = ismember(faces, find(aparc == iParc));
    boundary = unique([boundary reshape(faces(sum(parcfaces, 2) == 1, :), 1, [])]);
end

%% Map parcel values onto vertices
cdata = zeros(length(aparc), 1);
for iTarg = 2:table.numEntries                       % entry 1 is 'unknown'
    hit = strcmpi(targets, table.struct_names{iTarg});
    if any(hit)
        cdata(aparc == table.table(iTarg, 5)) = data(hit);
    else
        cdata(aparc == table.table(iTarg, 5)) = nan;
    end
end

%% Vertex colours
rgb = repmat(0.5, length(cdata), 3);
rgb(curv >= 0, :) = 0.3;                              % curvature shading

idx = cdata < -crange(1);                             % negative: blue -> cyan
t = min((abs(cdata(idx)) - crange(1)) / diff(crange), 1);
rgb(idx, :) = [zeros(sum(idx), 1) t ones(sum(idx), 1)];

idx = cdata >= crange(1);                             % positive: red -> yellow
t = min((abs(cdata(idx)) - crange(1)) / diff(crange), 1);
rgb(idx, :) = [ones(sum(idx), 1) t zeros(sum(idx), 1)];

rgb(boundary, :) = 0;

%% Draw
views = struct('lateral', [90 0], 'medial', [-90 0], 'ventral', [90 -90], 'dorsal', [90 90]);
if ~isfield(views, surfview), error('surfview must be lateral, medial, ventral or dorsal'); end
axis off
patch('Vertices', vertices, 'Faces', faces, 'FaceVertexCData', rgb, 'FaceLighting', 'gouraud');
material([.3 .8 .1 10 1])
shading interp
daspect([1 1 1])
view(views.(surfview))
camzoom(1.2)
if strcmp(surfname, 'pial'), camzoom(0.8), end
camlight('headlight', 'infinite')
end
