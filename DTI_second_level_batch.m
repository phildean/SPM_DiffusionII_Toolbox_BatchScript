function DTI_second_level_batch(todo)
%
spm_defaults;
weg='E:\MRI\mTBI\scripts';
group_compare={'mTBIplus_Controlminus' 'mTBIminus_Controlminus' 'mTBIplus_mTBIminus' 'mTBIall_Controlminus' 'mTBIplus_NoPCS'};

g(1).s=[3 6 10 14 17 26 30 31];g(1).name='mTBIplus';
g(2).s=[1 2 11 12 13 15 21 28];g(2).name='mTBIminus';
g(3).s=[5 8 9 16 19 20 23 24 29];g(3).name='Controlminus';
g(4).s=[3 6 10 14 17 26 30 31 1 2 11 12 13 15 21 28 5 8 9 16 19 20 23 24 29]; g(4).name='All';g(4).s=sort(g(4).s);
g(5).s=[1 2 11 12 13 15 21 28 3 6 10 14 17 26 30 31]; g(5).name='mTBIall';
g(6).s=[1 2 11 12 13 15 21 28 5 8 9 16 19 20 23 24 29]; g(6).name='NoPCS';

a(1).s=[36 37 21 24 19 26 19 23];a(1).name='mTBIplusAge';
a(2).s=[29 33 22 25 39 29 26 23];a(2).name='mTBIminusAge';
a(3).s=[25 22 20 32 20 23 18 18 19];a(3).name='ControlminusAge';
a(4).s=[36 37 21 24 19 26 19 23 29 33 22 25 39 29 26 23 25 22 20 32 20 23 18 18 19];a(4).name='AllAge';
a(5).s=[29 33 22 25 39 29 26 23 36 37 21 24 19 26 19 23];a(5).name='mTBIAllAge';
a(6).s=[29 33 22 25 39 29 26 23 25 22 20 32 20 23 18 18 19];a(6).name='NoPCSAge';


compare=[1 3;2 3;1 2;5 3;1 6]; %group contrasts

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% within group analysis: Model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strfind(todo,'w')
    load(fullfile(weg,'DTI\DTI_model_1T_Brain.mat'));
   for ii=1:length(g)
       Q=[];
       within_directory=['E:\MRI\mTBI\second_level\DTI_Analysis\DTI_10C_7M_7MP\within_groups\' g(ii).name];
       if ~exist((within_directory),'dir'); mkdir(within_directory); end;
   
      for jj = 1:length(g(ii).s)
          subj_number=num2str(g(ii).s(jj)); 
          howlong=length(subj_number);
               
        if howlong < 2 
            subjects=['Subject_0' num2str(subj_number)];
            D=['E:\MRI\mTBI\Data\' subjects '\DTI\DTI_Analysis\Tensor_Indices']; 
        else
            subjects=['Subject_' num2str(subj_number)];
            D=['E:\MRI\mTBI\Data\' subjects '\DTI\DTI_Analysis\Tensor_Indices']; 
        end;
       
          [P]=grabdata(D,'sfa_mwrs*.img');
          [Q] = [Q; [P]];
          clear P;
       
       end; %jj
   
   matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = Q;
   matlabbatch{1}.spm.stats.factorial_design.dir{1} = within_directory;
   
   clear Q;
 
  spm_jobman('run',matlabbatch);
  
   end; %ii
     
end;  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% within group analysis: Estimate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strfind(todo,'x')
    load(fullfile(weg,'DTI\DTI_estimate_1T.mat'));
   for ii=1:length(g)
       
       within_directory=['E:\MRI\mTBI\second_level\DTI_Analysis\DTI_10C_7M_7MP\within_groups\' g(ii).name];
       if ~exist((within_directory),'dir'); mkdir(within_directory); end;
               
   matlabbatch{1}.spm.stats.fmri_est.spmmat{1} = fullfile(within_directory, 'SPM.mat');
   
   spm_jobman('run',matlabbatch);
   
   load(matlabbatch{1}.spm.stats.fmri_est.spmmat{1});
   c = [1];
   xCon(1) = spm_FcUtil('Set','Main_Effect','T','c',c(:),SPM.xX.xKXs);
   SPM.xCon=xCon;
   c = [-1]; 	 
   cname               = ['Main_Effect_Minus'];
   SPM.xCon(end + 1)   = spm_FcUtil('Set',cname,'T','c',c(:),SPM.xX.xKXs);
   spm_contrasts(SPM);
   
   end; %ii
     
end; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% between group analysis: Model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strfind(todo,'b')
    load(fullfile(weg,'DTI\DTI_model_2T_WM_AGE.mat'));
   for ii=1:length(compare)
       Q = [];
       S = [];
       between_directory=['E:\MRI\mTBI\second_level\DTI_Analysis\DTI_RD_9C_8M_8MP_Age\between_groups\' group_compare{ii}];
       if ~exist((between_directory),'dir'); mkdir(between_directory); end;
         
       for jj = 1:length(g(compare(ii,1)).s)
          subj_one_number=num2str(g(compare(ii,1)).s(jj)); 
          howlong=length(subj_one_number);
               
        if howlong < 2 
            subjects=['Subject_0' num2str(subj_one_number)];
            D_one=['E:\MRI\mTBI\Data\' subjects '\DTI\DTI_Analysis\Tensor_Indices']; 
        else
            subjects=['Subject_' num2str(subj_one_number)];
            D_one=['E:\MRI\mTBI\Data\' subjects '\DTI\DTI_Analysis\Tensor_Indices']; 
        end;
       
          [P]=grabdata(D_one,'srd_wrs*.img');
          [Q] = [Q; [P]];
          
          clear P;
       
        end; %jj
        
        for kk = 1:length(g(compare(ii,2)).s)
          subj_two_number=num2str(g(compare(ii,2)).s(kk)); 
          howlong=length(subj_two_number);
               
        if howlong < 2 
            subjects=['Subject_0' num2str(subj_two_number)];
            D_two=['E:\MRI\mTBI\Data\' subjects '\DTI\DTI_Analysis\Tensor_Indices']; 
        else
            subjects=['Subject_' num2str(subj_two_number)];
            D_two=['E:\MRI\mTBI\Data\' subjects '\DTI\DTI_Analysis\Tensor_Indices']; 
        end;
       
          [R]=grabdata(D_two,'srd_wrs*.img');
          [S] = [S; [R]];
          
          clear R;
       
        end; %kk
    
   matlabbatch{1}.spm.stats.factorial_design.des.t2.scans1 = Q;
   matlabbatch{1}.spm.stats.factorial_design.des.t2.scans2 = S;
   matlabbatch{1}.spm.stats.factorial_design.dir{1} = between_directory;
   matlabbatch{1}.spm.stats.factorial_design.cov.c = [a(compare(ii,1)).s(:);a(compare(ii,2)).s(:)];
   
   spm_jobman('run',matlabbatch);
   
   clear Q;
   clear S;
   
   end; %ii
     
end;  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% between group analysis: Estimate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strfind(todo,'c')
    load(fullfile(weg,'DTI\DTI_estimate_2T.mat'));
   for ii=1:length(compare)
       
       between_directory=['E:\MRI\mTBI\second_level\DTI_Analysis\DTI_RD_9C_8M_8MP_Age\between_groups\' group_compare{ii}];
       if ~exist((between_directory),'dir'); mkdir(between_directory); end;
              
   matlabbatch{1}.spm.stats.fmri_est.spmmat{1} = fullfile(between_directory, 'SPM.mat');
   
   spm_jobman('run',matlabbatch);
   
   load(matlabbatch{1}.spm.stats.fmri_est.spmmat{1});
   c = [1 -1 0];
   xCon(1) = spm_FcUtil('Set','Group1_gt_Group2','T','c',c(:),SPM.xX.xKXs);
   SPM.xCon=xCon;
   c = [-1 1 0]; 	 
   cname               = ['Group2_gt_Group1'];
   SPM.xCon(end + 1)   = spm_FcUtil('Set',cname,'T','c',c(:),SPM.xX.xKXs);
   spm_contrasts(SPM);
   
   end; %ii
     
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