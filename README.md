# SPM_DiffusionII_Toolbox_BatchScript
Script for running subjects through DiffusionII Toolbox in SPM

This script was written for SPM8 (and the script relies on spm_get.m from spm 5), and runs subjects through the diffusion II toolbox:

https://www.fil.ion.ucl.ac.uk/spm/ext/#Diffusion_II

https://sourceforge.net/projects/spmtools/

https://sourceforge.net/p/spmtools/diffusion/code/ci/master/tree/

It therefore needs the Diffusion Toolbox to be installed. 

meta_DTI is used to run dti_preprocess, with each stage given by a specific letter:

    d: reset DTI information
    r: realign DW time series
    c: coregister
    n: normalisation
    k: copy and reorient diffusion information
    a: Compute ADC images
    t: Compute Tensor
    e: Tensor Decomposition
    f: Tensor Indices
    g: ghost masking 
    s: Smoothing
    x: Extract DW information
    m: Move reset (s) and realign (means) data to new folder

NB: Ghost Masking ('g') looks for the brainmask in spm8, and will need updated: 

    mask_directory='E:\MRI\spm8\apriori';
    [M]=grabdata(mask_directory,'brainmask.nii');

DTI_second_level_batch runs the second level analyses directly, again by calling a letter:

    w: within group analysis: Model
    x: within group analysis: Estimate
    b: between group analysis: Model
    c: between group analysis: Estimate

It is not very well annotated, and was adapted a few times. 

It was used in the DTI analysis in:
Philip J. A. Dean, Joao Ricardo Sato, Gilson Vieira, Adam McNamara & Annette Sterr (2015) Long-term structural changes after mTBI and their relation to post-concussion symptoms, Brain Injury, 29:10, 1211-1218, DOI: 10.3109/02699052.2015.1035334 
