% Make_DTI_lists.m - Setup Pipeline lists for DTI preprocessing workflow
%
% For a given experiment directory, this script checks to see how many DTI
% scan repetitions are present, and generates the appropriate input lists
% for the DTI_preprocessing.pipe workflow in the .../exptDir/PIPELINE directory.
%
% Set Pipeline variable 'exptDir' to the same as below. Then run the workflow.
%
% Notes:
% 1. To run script from command line: matlab -nodisplay < Trio_DTI_lists.m
% 2. To clear out a whole area, do something like: rm SUBJECTS/*/1avg/dtifit/*
% 3. Change 'SUBJECTS' to 'TEST' at line 47 to use a test area

% Author: John Colby (johncolby@ucla.edu)

%% Setup
clear all

exptDir = '/path/to/exptDir/';  % Set experiment directory
outName = '2avg';               % Set the name of the output folder
nScans  = 2;                    % Choose the # of scans to average
idStr   = '30DIR';              % Specify a string to identify raw DWI series

D       = dir(fullfile(exptDir, 'SUBJECTS/20*'));  % Fetch subject list automatically
subIDs  = str2num(vertcat(D.name));
% subIDs = 20037;                                  % Also can specify subjects(s)
% load(fullfile(exptDir, 'SCRIPTS/subIDs.txt'))    % or load up a list


%% Open files for output
inpt = fopen(fullfile(exptDir, 'PIPELINE', 'inpt.list'),'wt');
dti  = fopen(fullfile(exptDir, 'PIPELINE', 'dti.list'),'wt');
data = fopen(fullfile(exptDir, 'PIPELINE', 'data.list'),'wt');
bet  = fopen(fullfile(exptDir, 'PIPELINE', 'bet.list'),'wt');
mask = fopen(fullfile(exptDir, 'PIPELINE', 'mask.list'),'wt');
bvec = fopen(fullfile(exptDir, 'PIPELINE', 'bvec.list'),'wt');
bval = fopen(fullfile(exptDir, 'PIPELINE', 'bval.list'),'wt');
dtk  = fopen(fullfile(exptDir, 'PIPELINE', 'dtk.list'),'wt');
dtk2 = fopen(fullfile(exptDir, 'PIPELINE', 'dtk2.list'),'wt');
fa   = fopen(fullfile(exptDir, 'PIPELINE', 'fa.list'),'wt');

%% Generate Pipeline input lists
for i=1:length(subIDs) % Loop over subject ID
    subStr = num2str(subIDs(i));
    
    % Change 'SUBJECTS' to 'TEST' to use a test area
    subDir = fullfile(exptDir, 'SUBJECTS', subStr);
    analysisDir = fullfile(subDir, outName);
    
    % Check to see if there are DTI scans present, and how many
    D = dir(fullfile(subDir, 'RAW', sprintf('*%s*.nii.gz', idStr)));
    
    if length(D)>=nScans
        % Make folders if needed
        if ~isdir(fullfile(analysisDir, 'dtifit')), mkdir(fullfile(analysisDir, 'dtifit')); end
        if ~isdir(fullfile(analysisDir, 'track')), mkdir(fullfile(analysisDir, 'track')); end
        if ~isdir(fullfile(analysisDir, 'diffusion_toolkit')), mkdir(fullfile(analysisDir, 'diffusion_toolkit')); end
        
        % Only do tensor fitting for subjects who don't have it already
        if isempty(dir(fullfile(analysisDir, 'dtifit/dti*'))) || isempty(dir(fullfile(analysisDir, 'diffusion_toolkit/dti*')))
            [tmp files] = unix(sprintf('echo `ls %s | head -%d`', fullfile(subDir, sprintf('*%s*.nii.gz', idStr)), nScans));
            fprintf(inpt, sprintf('%s', files));
            fprintf(dti,  sprintf('%s\n', fullfile(analysisDir, 'dtifit')));
            fprintf(data, sprintf('%s\n', fullfile(analysisDir, 'track/data.nii.gz')));
            fprintf(bet,  sprintf('%s\n', fullfile(analysisDir, 'track/nodif_brain.nii.gz')));
            fprintf(mask, sprintf('%s\n', fullfile(analysisDir, 'track/nodif_brain_mask.nii.gz')));
            fprintf(bvec, sprintf('%s\n', fullfile(exptDir, 'PIPELINE/grad', sprintf('bvecs%d', nScans))));
            fprintf(bval, sprintf('%s\n', fullfile(exptDir, 'PIPELINE/grad', sprintf('bvals%d', nScans))));
            fprintf(dtk,  sprintf('%s\n', fullfile(analysisDir, 'diffusion_toolkit', 'dti')));
            fprintf(dtk2, sprintf('%s\n', fullfile(analysisDir, 'diffusion_toolkit', 'dti.trk')));
            fprintf(fa,   sprintf('%s\n', fullfile(analysisDir, 'diffusion_toolkit', 'dti_fa.nii.gz')));
            
            % Make links to the correct bvals/bvecs in the track folder
            if ~exist(fullfile(analysisDir, 'track/bvals'), 'file')
                unix(sprintf('ln -s %s %s', fullfile(exptDir, 'PIPELINE/grad', sprintf('bvals%d', nScans)), ...
                    fullfile(analysisDir, 'track/bvals')));
                unix(sprintf('ln -s %s %s', fullfile(exptDir, 'PIPELINE/grad', sprintf('bvecs%d', nScans)), ...
                    fullfile(analysisDir, 'track/bvecs')));
            end
        end
    end
end

%% Clean up
fclose all;

% Set permissions so Pipeline can read the files
unix(sprintf('chmod a+rw %s', fullfile(exptDir, 'PIPELINE/*.list')));