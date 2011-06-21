#!/usr/bin/env python
import argparse

parser = argparse.ArgumentParser(formatter_class=argparse.RawDescriptionHelpFormatter,
description='\
For a given experiment directory, this script checks to see how many DTI scan\n\
repetitions are present, and generates the appropriate input lists for the\n\
DTI_preprocessing.pipe workflow in the <exptDir>/PIPELINE directory.',
epilog='Example: make_DTI_lists.py /path/to/exptDir 2avg 2 30DIR -s `ls /path/to/exptDir/SUBJECTS | grep <some pattern goes here>`')

parser.add_argument('exptDir', action='store',
                    help='Path to base experiment directory. Should contain SUBJECTS and PIPELINE directories.')
parser.add_argument('outName', action='store',
                    help='Desired output directory name that will be created in each <exptDir>/SUBJECTS/<subID>/ directory.')
parser.add_argument('nScans', action='store', type=int,
                    help='Choose the number of scans to average.')
parser.add_argument('idStr', action='store',
                    help='Specify a string to identify raw DWI series.')
parser.add_argument('-s', action='store', nargs='+', dest='subIDs',
                    help='Subset of subject ID directories in <exptDir>/SUBJECTS to process. Default is to process all subjects.')

args = parser.parse_args()

import os
from os.path import *
from glob import *

def makeDirs(analysisDir):
    # Setup output directory structure if needed
    
    if not isdir(join(analysisDir, 'dtifit')):
        os.makedirs(join(analysisDir, 'dtifit'))
    if not isdir(join(analysisDir, 'track')):
        os.makedirs(join(analysisDir, 'track'))
    if not isdir(join(analysisDir, 'diffusion_toolkit')):
        os.makedirs(join(analysisDir, 'diffusion_toolkit'))

def make_DTI_lists(exptDir, outName, nScans, idStr, subIDs=''):
    # Function to generate Pipeline lists
    
    # Convert exptDir to full path
    exptDir = abspath(exptDir)
    
    # Get full subject list if subIDs is not given
    if not subIDs:
        subIDs = sorted(os.listdir(join(exptDir, 'SUBJECTS')))
    
    # Open files for output
    with open(join(exptDir, 'PIPELINE', 'inpt.list'), 'w') as inpt,\
         open(join(exptDir, 'PIPELINE', 'dti.list'), 'w')  as dti,\
         open(join(exptDir, 'PIPELINE', 'data.list'), 'w') as data,\
         open(join(exptDir, 'PIPELINE', 'bet.list'), 'w')  as bet,\
         open(join(exptDir, 'PIPELINE', 'mask.list'), 'w') as mask,\
         open(join(exptDir, 'PIPELINE', 'bvec.list'), 'w') as bvec,\
         open(join(exptDir, 'PIPELINE', 'bval.list'), 'w') as bval,\
         open(join(exptDir, 'PIPELINE', 'dtk.list'), 'w')  as dtk,\
         open(join(exptDir, 'PIPELINE', 'dtk2.list'), 'w') as dtk2,\
         open(join(exptDir, 'PIPELINE', 'fa.list'), 'w')   as fa:
         
        # Loop over subject ID
        for subject in subIDs:
            
            # Change 'SUBJECTS' to 'TEST' to use a test area
            subDir      = join(exptDir, 'SUBJECTS', subject)
            analysisDir = join(subDir, outName)
            
            # Check to see if there are DTI scans present, and how many
            files = sorted(glob(join(subDir, 'RAW', '*' + idStr + '*.nii.gz')))
            
            print(str(subject) + '\t'),
            
            if len(files) >= nScans:
                makeDirs(analysisDir)
                
                # Only set up tensor fitting to run for subjects who don't have
                # files already
                if not (glob(join(analysisDir, 'dtifit/dti*')) or\
                        glob(join(analysisDir, 'diffusion_toolkit/dti*'))):
                    print >> inpt, ' '.join(files[0:nScans])
                    print >> dti,  join(analysisDir, 'dtifit')
                    print >> data, join(analysisDir, 'track/data.nii.gz')
                    print >> bet,  join(analysisDir, 'track/nodif_brain.nii.gz')
                    print >> mask, join(analysisDir, 'track/nodif_brain_mask.nii.gz')
                    print >> bvec, join(exptDir, 'PIPELINE/grad', 'bvecs' + str(nScans))
                    print >> bval, join(exptDir, 'PIPELINE/grad', 'bvals' + str(nScans))
                    print >> dtk,  join(analysisDir, 'diffusion_toolkit', 'dti')
                    print >> dtk2, join(analysisDir, 'diffusion_toolkit', 'dti.trk')
                    print >> fa,   join(analysisDir, 'diffusion_toolkit', 'dti_fa.nii.gz')
                    
                    print('OK\t'),
                    
                    # Make links to the correct bvals/bvecs in the track folder
                    # for bedpostx
                    try:
                        os.symlink(join(exptDir, 'PIPELINE/grad', 'bvals' + str(nScans)),\
                                   join(analysisDir, 'track/bvals'))
                    except OSError as err:
                        print('bvals: ' + str(err) + '\t'),
                    try:
                        os.symlink(join(exptDir, 'PIPELINE/grad', 'bvecs' + str(nScans)),\
                                   join(analysisDir, 'track/bvecs'))
                    except OSError as err:
                        print('bvecs: ' + str(err))
                else:
                    print('DTI files already present')
            else:
                print('Not enough scans')

make_DTI_lists(args.exptDir, args.outName, args.nScans, args.idStr, args.subIDs)