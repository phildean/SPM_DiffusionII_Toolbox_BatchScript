function dti_preprocess(todo,D)
  
% second argument is Directory  'E:\MRI\mTBI\Data\Subject_31'
% d: reset DTI information
% r: realign DW time series
% c: coregister
% n: normalisation
% k: copy and reorient diffusion information
% a: Compute ADC images
% t: Compute Tensor
% e: Tensor Decomposition
% f: Tensor Indices
% g: ghost masking 
% s: Smoothing
% x: Extract DW information
% m: Move reset (s) and realign (means) data to new folder
%
% So, e.g: dti_preprocess('drcnkatefgsxm','E:\MRI\mTBI\Data\Subject_31')
  

spm_defaults;
weg='E:\MRI\mTBI\scripts';
global defaults


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reset DTI Information (Gradient, bvalue and position)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   bval = [0; 1000; 1000; 1000; 1000; 1000; 1000; 1000; 1000; 1000; 1000;
% 1000; 1000]
%   bvec = [0 0 0; 0.89439 0 -0.44729; 0 0.44725 -0.89441; 0.44717 0.89445 0;
%0.89439 0.44729 0; 0 0.89441 -0.44725; 0.44717 0 -0.89445; 0.89443 0
%0.44721; 0 -0.44717 -0.89445; -0.44725 0.89441 0; 0.89443 -0.44721 0; 0
%0.89445 0.44717; -0.44725 0 -0.89441]

if strfind(todo,'d')
 
%%%% creates a directory, and copies dicom imported files into new directory, so original imports un-changed, and analysis can be redone easily.    
directory=fullfile(D,['DTI']); 
if ~exist(fullfile(directory,'DTI_Analysis'),'dir'); cd(directory); mkdir('DTI_Analysis'); end; 
   analyse_directory=fullfile(directory,['DTI_Analysis']);
   copyfile ('s*.hdr',analyse_directory); 
   copyfile ('s*.img',analyse_directory);     
  
   %%%% Loads batch file 
   load(fullfile(weg,'DTI\DTI_Reset.mat'));
  
   %%%% Gets Data (See "Grabdata" below). Grabdata requires spm_get.m from
   %%%% spm5
   [P]=grabdata(analyse_directory,'s*.img');
   
   %%%% Puts source images (s*.img) in
   for ii=1:size(P{1},1);
     matlabbatch{1}.spm.tools.vgtbx_Diffusion.dti_init_dtidata.srcimgs{ii} = P{1}(ii,:);
   end
   %%%% clears array
   clear P;
   %%%% runs process
   spm_jobman('run',matlabbatch);
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Realign DW Time Series (Realign B to B0, and creates mean)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% realign xy and coregister to mean

if strfind(todo,'r')
    %%%% tells loop what directory to look in for data
    directory=fullfile(D,['DTI']);
    analyse_directory=fullfile(directory,['DTI_Analysis']);
    
    load(fullfile(weg,'DTI\DTI_Realign.mat'));
    
    [P]=grabdata(analyse_directory,'s*.img');
   
   %%%% Puts source images (s*.img) in 
   for ii=1:size(P{1},1);
     matlabbatch{1}.spm.tools.vgtbx_Diffusion.dti_realign.srcimgs{ii} = P{1}(ii,:);
   end
   clear P;
   spm_jobman('run',matlabbatch);
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Coregister (reslice) (reslice B so in line with B0, creates r*.img)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4th degree B-spline used 

if strfind(todo,'c')
    directory=fullfile(D,['DTI']);
    analyse_directory=fullfile(directory,['DTI_Analysis']);
    load(fullfile(weg,'DTI\DTI_Coregister.mat'));
    
    [P]=grabdata(analyse_directory,'means*.img');
    [Q]=grabdata(analyse_directory,'s*.img');
    
    %%%% Puts mean file image (means*.img) in
    matlabbatch{1}.spm.spatial.coreg.write.ref{1} = P{1}(1,:);
 
    %%%% Puts source images (s*.img) in 
 for ii=1:size(Q{1},1); 
    matlabbatch{1}.spm.spatial.coreg.write.source{ii} = Q{1}(ii,:);
 end
 clear P;
 clear Q;
 spm_jobman('run',matlabbatch);
 
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Normalization (normalise to own structural, and average structural,
% creates w*.img)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subject options: no weighting currently used - can use lesion mask here
% (wtsrc)
% estimate options: smooth source image = 8; template: 'E:\MRI\spm8\templates\EPI.nii,1'; weighted by
%'E:\MRI\spm8\apriori\brainmask.nii,1';
% rewrite options: 4th degree B-spline used

if strfind(todo,'n')
    directory=fullfile(D,['DTI']);
    %%%% directory for structural image
    structural_directory=fullfile(D,['structural']);
    analyse_directory=fullfile(directory,['DTI_Analysis']);
    load(fullfile(weg,'DTI\DTI_Normalisation.mat'));
    
   [S]=grabdata(structural_directory,'s*.img'); 
   [P]=grabdata(analyse_directory,'rs*.img'); % change this to 's*.img' if dont want to do coregister

%%%% Puts structural image (s*.img) in    
matlabbatch{1}.spm.spatial.normalise.estwrite.subj.source{1} = S{1}(1,:);

%%%% Puts realigned/coregistered images (rs*.img) in 
for ii=1:size(P{1},1); 
matlabbatch{1}.spm.spatial.normalise.estwrite.subj.resample{ii} = P{1}(ii,:);
end;
clear S;
clear P;

spm_jobman('run',matlabbatch);

end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copy and reorient diffusion information (diffusion info reorient to
% resliced images)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Rotation: Yes, Zoom: signs and magnitude; Shear: Yes

if strfind(todo,'k')
    directory=fullfile(D,['DTI']);
    analyse_directory=fullfile(directory,['DTI_Analysis']);
    load(fullfile(weg,'DTI\DTI_CopyReorient.mat'));
    
    [P]=grabdata(analyse_directory,'s*.img');
    [Q]=grabdata(analyse_directory,'wrs*.img');
    
    %%%% Puts source images (s*.img) in 
   for ii=1:size(P{1},1);  
    matlabbatch{1}.spm.tools.vgtbx_Diffusion.dti_reorient_gradient.srcimgs{ii} = P{1}(ii,:);
   end;
   
   %%%% Puts realigned/coregistered/normalised images (wrs*.img) in 
   for ii=1:size(Q{1},1);
    matlabbatch{1}.spm.tools.vgtbx_Diffusion.dti_reorient_gradient.tgtimgs{ii} = Q{1}(ii,:);
   end;
   
   clear P;
   clear Q;
   
   spm_jobman('run',matlabbatch);

end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute ADC images (creates apparent diffusion coefficient, adc_rs*.ima)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Interpolation: 4th Degree B-Spline

if strfind(todo,'a')
    directory=fullfile(D,['DTI']);
    analyse_directory=fullfile(directory,['DTI_Analysis']);
    load(fullfile(weg,'DTI\DTI_ADCImages.mat'));
    
    [P]=grabdata(analyse_directory,'wrs*.img');
    
     %%%% Puts in B0 image, wrs*.img 
    matlabbatch{1}.spm.tools.vgtbx_Diffusion.dti_adc.file0{1} = P{1}(1,:);
    
    %%%% Puts in all other images (B1-12), all wrs*.img
  for ii=1:((size(P{1},1))-1); 
      matlabbatch{1}.spm.tools.vgtbx_Diffusion.dti_adc.files1{ii} = P{1}((ii+1),:);
  end;
  
  clear P;
 
  spm_jobman('run',matlabbatch);
  
  %%%% moves ADC images to seperate folder "ADC_Images" 
  if ~exist(fullfile(analyse_directory,'ADC_Images'),'dir'); cd(analyse_directory); mkdir('ADC_Images'); end;
    adc_directory=fullfile(analyse_directory,['ADC_Images']);
    copyfile ('adc_wrs*.hdr', adc_directory); 
    copyfile ('adc_wrs*.img', adc_directory);
    copyfile ('adc_wrs*.mat', adc_directory);
    cd(analyse_directory);
    delete('adc_wrs*.hdr','adc_wrs*.img','adc_wrs*.mat');   
end;
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute Tensor (Multiple Regression) (creates diffusion weighted images, Dxx, Dyy, Dzz etc)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
% Can use Mask image by 'E:\MRI\spm8\apriori\brainmask.nii,1' by using
% DTI_ComputeTensor_mask.mat. Or if not required, use DTI_ComputeTensor
% Error Variance Options: Equal errors, equal variance; Tensor Order: 2;
% Estimates spatial smoothness
    
if strfind(todo,'t')
    directory=fullfile(D,['DTI']);
    analyse_directory=fullfile(directory,['DTI_Analysis']);
    
    %%%% change between these two batch files depending on whether you want
    %%%% to use brainmask
    
    %load(fullfile(weg,'DTI\DTI_ComputeTensor.mat'));
    load(fullfile(weg,'DTI\DTI_ComputeTensor_mask.mat'));
        
    [P]=grabdata(analyse_directory,'wrs*.img');
    
    %%%% assigns the output directory
    matlabbatch{1}.spm.tools.vgtbx_Diffusion.dti_dt_regress.swd{1} = analyse_directory;
  
   %%%% Puts realigned/coregistered/normalised images (wrs*.img) in 
  for ii=1:size(P{1},1);  
    matlabbatch{1}.spm.tools.vgtbx_Diffusion.dti_dt_regress.srcimgs{ii} = P{1}(ii,:);
  end;
  clear P;
  spm_jobman('run',matlabbatch);
    
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Tensor Decomposition (creates eigenvalues/vectors, eval*.ima, evec*.ima)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Eigenvectors and eigenvalues
    
if strfind(todo,'e')
    directory=fullfile(D,['DTI']);
    analyse_directory=fullfile(directory,['DTI_Analysis']);
    
    load(fullfile(weg,'DTI\DTI_TensorDecomposition.mat'));
    
    [P]=grabdata(analyse_directory,'D*.img');
    
    %%%% Puts Tensor values (Dxx, Dyy, Dzz etc) in 
    for ii=1:size(P{1},1); 
      matlabbatch{1}.spm.tools.vgtbx_Diffusion.dti_eig.dtimg{ii} = P{1}(ii,:);
    end;
    clear P;
    
    spm_jobman('run',matlabbatch);
    
end;
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Tensor Indices (average diffusivity, ad-rs*.ima; Variance, va_rs*.ima; Fractional Anisotropy, fa_rs*.ima created)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
% Compute ALL (FA, Average Diffusivity, Variance)
    
if strfind(todo,'f')
    directory=fullfile(D,['DTI']);
    analyse_directory=fullfile(directory,['DTI_Analysis']);
    %%%% creates a file "Tensor_Indices" wihin DTI_Analysis and copies Dxx, Dyy etc images in. This prevents the overwriting of the SPM.mat file 
    if ~exist(fullfile(analyse_directory,'Tensor_Indices'),'dir'); cd(analyse_directory); mkdir('Tensor_Indices'); end;
    indices_directory=fullfile(analyse_directory,['Tensor_Indices']);
    copyfile ('D*.hdr',indices_directory); 
    copyfile ('D*.img',indices_directory); 
    
    load(fullfile(weg,'DTI\DTI_TensorIndices.mat'));
    
    [P]=grabdata(indices_directory,'D*.img');
    
    %%%% Puts Tensor values (Dxx, Dyy, Dzz etc) in 
    for ii=1:size(P{1},1); 
      matlabbatch{1}.spm.tools.vgtbx_Diffusion.dti_indices.dtimg{ii} = P{1}(ii,:);
    end;
    clear P;
    
    spm_jobman('run',matlabbatch);
    
end; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ghost Masking 
% Expression: 'i1.*12'; No Implicit Zero mask; 4th Degree Sinc Interpolation;
% No Data Matrix; INT 16 Data Type
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strfind(todo,'g')
    directory=fullfile(D,['DTI']);
    analyse_directory=fullfile(directory,['DTI_Analysis']);
    indices_directory=fullfile(analyse_directory,['Tensor_Indices']);
    
    %%%% Looks for mask image and 'grabs' it
    mask_directory='E:\MRI\spm8\apriori';
    [M]=grabdata(mask_directory,'brainmask.nii');
    
    %%%% Creates arrays of the input and output files to be masked
    input_name = {'fa_wrs*.img' 'ad_wrs*.img' 'va_wrs*.img'};
    output_name = {'fa_mwrs_ImCalc.img' 'ad_mwrs_ImCalc.img' 'va_mwrs_ImCalc.img'};
    
    load(fullfile(weg,'DTI\DTI_Mask.mat'));
    
    for ii = 1:length(input_name);
    [P]=grabdata(indices_directory,input_name{ii});
   
    %%%% Files to input for expression
    matlabbatch{1}.spm.util.imcalc.input{1} = P{1}(1,:);
    matlabbatch{1}.spm.util.imcalc.input{2} = M{1}(1,:);
    
    %%%% Output_directory
    matlabbatch{1}.spm.util.imcalc.outdir{1} = indices_directory;
    
    %%%%File names to output
    matlabbatch{1}.spm.util.imcalc.output = output_name{ii};
    
    clear P;
    
    spm_jobman('run',matlabbatch);
    end;
    
end;    


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Smoothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Smoothing = 8

if strfind(todo,'s')
    directory=fullfile(D,['DTI']);
    analyse_directory=fullfile(directory,['DTI_Analysis']);
    indices_directory=fullfile(analyse_directory,['Tensor_Indices']);
        
    load(fullfile(weg,'DTI\DTI_Smooth.mat'));
    
    [P]=grabdata(indices_directory,'fa_mwrs*.img');
    [Q]=grabdata(indices_directory,'ad_mwrs*.img');
    [R]=grabdata(indices_directory,'va_mwrs*.img');
    
    %%%% Puts Tensor Indices (FA, Average Diffusivity, Variance) in 
    matlabbatch{1}.spm.spatial.smooth.data{1} = P{1}(1,:);
    matlabbatch{1}.spm.spatial.smooth.data{2} = Q{1}(1,:);
    matlabbatch{1}.spm.spatial.smooth.data{3} = R{1}(1,:);
    
    clear P;
    clear Q;
    clear R;
    
    spm_jobman('run',matlabbatch);
    
end; 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extract DW information (create a file of the new vectors/beta values. these change during the processing)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% B Value tolerance/ Gradient value tolerance = 1; distinguish antiparallel
% directions

if strfind(todo,'x')
    directory=fullfile(D,['DTI']);
    analyse_directory=fullfile(directory,['DTI_Analysis']);
    
    load(fullfile(weg,'DTI\DTI_ExtractDWInfo.mat'));
    
    [P]=grabdata(analyse_directory,'wrs*.img');
    
    %%%% Puts realigned/coregistered/normalised images (wrs*.img) in
    for ii=1:size(P{1},1); 
      matlabbatch{1}.spm.tools.vgtbx_Diffusion.dti_extract_dirs.srcimgs{ii} = P{1}(ii,:);
    end;
    clear P;
    
    spm_jobman('run',matlabbatch);
    
    %%%% copies these txt files with the new vectors into a new folder for
    %%%% ease of access
    if ~exist(fullfile(analyse_directory,'New_BVal_BVec'),'dir'); cd(analyse_directory); mkdir('New_BVal_BVec'); end;
    bvalvec_directory=fullfile(analyse_directory,['New_BVal_BVec']);
    copyfile ('wrs*.txt',bvalvec_directory);
    cd(analyse_directory);
    delete('wrs*.txt');
    
end; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Move reset (s) and realign (means) data to new folder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strfind(todo,'m')
    
    directory=fullfile(D,['DTI']);
    analyse_directory=fullfile(directory,['DTI_Analysis']);
    
 %%%% moves reset and realign images to seperate folder "Early_Processing" 
  if ~exist(fullfile(analyse_directory,'Early_Processing'),'dir'); cd(analyse_directory); mkdir('Early_Processing'); end;
    early_directory=fullfile(analyse_directory,['Early_Processing']);
    copyfile ('s*.hdr', early_directory); 
    copyfile ('s*.img', early_directory);
    copyfile ('s*.mat', early_directory);
    copyfile ('means*.hdr', early_directory);
    copyfile ('means*.img', early_directory);
    copyfile ('spm*.ps', early_directory);
    cd(analyse_directory);
    delete('s*.hdr','s*.img','s*.mat', 'means*.hdr', 'means*.img', 'spm*.ps');
    %%%% Copies SPM.mat over too - so needs to copy it back!    
    cd(early_directory);
    copyfile ('SPM.mat', analyse_directory);
    delete('SPM.mat');

end;


%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Grabdata requires spm_get.m from
%%%% spm5
function [P]=grabdata(directory,type);
%grabs files
spm_defaults;
global defaults
P = cell(1,1);
P{1}   = spm_get('Files',directory,type);