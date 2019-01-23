function [mem] = meta_DTI(shift)
% META FILE - runs specific programs for each subject in turn

%subject independent information
sh.studypath = 'E:\MRI\mTBI\Data';
sh.imagepath = 'E:\MRI\mTBI\Data';


mypwd = pwd;
addpath(mypwd);
global ev
ev = {};

% subject-specific information

for jj = 1:9; subj(jj).path = ['Subject_0' num2str(jj)] ; end;
for jj = 10:31; subj(jj).path = ['Subject_' num2str(jj)]; end;

%%%%    mem=[];
for i = 1:length(subj)
   if i ~= 10
spm_defaults;

%first define directory name
   fprintf('\nSubject %s',num2str(i));
   fprintf(' --- Preprocessing DTI');
  
%%%%   try
% do DTI (drcnkatefgsxm)
     dti_preprocess('drcnkatefgsxm', fullfile(sh.studypath,subj(i).path));

%%%%    mem(i)=1;
%%%%   catch
%%%%    mem(i)=0;
%%%%    end

end;
end;