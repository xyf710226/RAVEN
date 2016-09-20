function newModel=addMets(model,metsToAdd,copyInfo)
% addMets
%   Adds metabolites to a model
%
%   model        a model structure
%   metsToAdd    the metabolite structure can have the following fields:
%                mets           cell array with unique strings that 
%                               identifies each metabolite (opt, default is
%                               that new metabolites that are added will be
%                               assigned IDs "m1", "m2"... If IDs on the same
%                               form are already used in the model then the
%                               numbering will start from the highest existing
%                               integer+1)
%                metNames       cell array with the names of each
%                               metabolite
%                compartments   cell array with the compartment of each
%                               metabolite. Should match model.comps.
%                               If this is a string rather than a cell
%                               array it is assumed that all mets are in
%                               that compartment
%                b              Nx1 or Nx2 matrix with equality constraints
%                               for each metabolite (opt, default 0)
%                unconstrained  vector describing if each metabolite is an
%                               exchange metabolite (1) or not (0) (opt,
%                               default 0)
%                inchis         cell array with InChI strings for each
%                               metabolite (opt, default '')
%                metFormulas    cell array with the formulas for each of
%                               the metabolites (opt, default '')
%                metMiriams     cell array with MIRIAM structures (opt,
%                               default [])
%   copyInfo     when adding metabolites to a compartment where it previously
%                doesn't exist, the function will copy any available annotation 
%                from the metabolite in another compartment (opt, default true)
%
%   newModel     an updated model structure
%
%   NOTE: This function does not make extensive checks about MIRIAM formats,
%   forbidden characters or such.
%
%   Usage: newModel=addMets(model,metsToAdd,copyInfo)
%
%   Rasmus Agren, 2013-08-01
%

if nargin<3
   copyInfo=true; 
end

newModel=model;

if isempty(metsToAdd)
    return;
end

%Check some stuff regarding the required fields
if ~isfield(metsToAdd,'mets')
    %Name the metabolites as "m1, m2...". If IDs on the same form are already
    %used in the model then the first available integers should be used
    maxCurrent=ceil(max(cellfun(@getInteger,model.mets)));
    m=maxCurrent+1:maxCurrent+numel(metsToAdd.metNames);
    metsToAdd.mets=strcat({'m'},num2str(m(:)));
end
if ~isfield(metsToAdd,'metNames')
    dispEM('metNames is a required field in metsToAdd');
end
if ~isfield(metsToAdd,'compartments')
    dispEM('compartments is a required field in metsToAdd');
end

if ~iscellstr(metsToAdd.mets)
    dispEM('metsToAdd.mets must be a cell array of strings');
end
if ~iscellstr(metsToAdd.metNames)
    dispEM('metsToAdd.metNames must be a cell array of strings');
end
if ~iscellstr(metsToAdd.compartments)
    if ischar(metsToAdd.compartments)
        temp=cell(numel(metsToAdd.mets),1);
        temp(:)={metsToAdd.compartments};
        metsToAdd.compartments=temp;
    else
        dispEM('metsToAdd.compartments must be a cell array of strings');
    end
end

%Number of metabolites
nMets=numel(metsToAdd.mets);
nOldMets=numel(model.mets);
filler=cell(nMets,1);
filler(:)={''};
largeFiller=cell(nOldMets,1);
largeFiller(:)={''};

%Check that no metabolite ids are already present in the model
I=ismember(metsToAdd.mets,model.mets);
if any(I)
	dispEM('One or more elements in metsToAdd.mets are already present in model.mets');
else
    newModel.mets=[newModel.mets;metsToAdd.mets(:)];
end

%Check that all the compartments could be found
[I compMap]=ismember(metsToAdd.compartments,model.comps);
if ~all(I)
    dispEM('metsToAdd.compartments must match model.comps');
end

%Check that the metabolite names aren't present in the same compartment.
%Not the neatest way maybe..
t1=strcat(metsToAdd.metNames(:),'���',metsToAdd.compartments(:));
t2=strcat(model.metNames,'���',model.comps(model.metComps));
if any(ismember(t1,t2))
    dispEM('One or more elements in metsToAdd.metNames already exist in the same compartments as the one it is being added to');
end

%Some more checks and if they pass then add each field to the structure
if numel(metsToAdd.metNames)~=nMets
   dispEM('metsToAdd.metNames must have the same number of elements as metsToAdd.mets');
else
    newModel.metNames=[newModel.metNames;metsToAdd.metNames(:)];
end

if numel(compMap)~=nMets
   dispEM('metsToAdd.compartments must have the same number of elements as metsToAdd.mets');
else
    newModel.metComps=[newModel.metComps;compMap];
end

if isfield(metsToAdd,'b')
   if size(metsToAdd.b,1)~=nMets
       dispEM('metsToAdd.b must have the same number of elements as metsToAdd.mets');
   else
       %Add empty field if it doesn't exist
       if ~isfield(newModel,'b')
            newModel.b=zeros(nOldMets,1);
       end
       
       %If the original is only one vector
       if size(metsToAdd.b,2)>size(newModel.b,2)
           newModel.b=[newModel.b newModel.b];
       end
       %Add the new ones
       newModel.b=[newModel.b;metsToAdd.b];
   end
else
    if isfield(newModel,'b')
        %Add the default
        newModel.b=[newModel.b;zeros(nMets,size(newModel.b,2))];
    end
end

if isfield(metsToAdd,'unconstrained')
   if numel(metsToAdd.unconstrained)~=nMets
       dispEM('metsToAdd.unconstrained must have the same number of elements as metsToAdd.mets');
   else
       %Add empty field if it doesn't exist
       if ~isfield(newModel,'unconstrained')
            newModel.unconstrained=zeros(nOldMets,1);
       end
       
       %Add the new ones
       newModel.unconstrained=[newModel.unconstrained;metsToAdd.unconstrained(:)];
   end
else
    if isfield(newModel,'unconstrained')
        %Add the default
        newModel.unconstrained=[newModel.unconstrained;zeros(nMets,1)];
    end
end

if isfield(metsToAdd,'inchis')
   if numel(metsToAdd.inchis)~=nMets
       dispEM('metsToAdd.inchis must have the same number of elements as metsToAdd.mets');
   end
   if ~iscellstr(metsToAdd.inchis)
        dispEM('metsToAdd.inchis must be a cell array of strings');
   end
   %Add empty field if it doesn't exist
   if ~isfield(newModel,'inchis')
        newModel.inchis=largeFiller;
   end
   newModel.inchis=[newModel.inchis;metsToAdd.inchis(:)];
else
    %Add empty strings if structure is in model
    if isfield(newModel,'inchis')
       newModel.inchis=[newModel.inchis;filler];
    end
end

if isfield(metsToAdd,'metFormulas')
   if numel(metsToAdd.metFormulas)~=nMets
       dispEM('metsToAdd.metFormulas must have the same number of elements as metsToAdd.mets');
   end
   if ~iscellstr(metsToAdd.metFormulas)
        dispEM('metsToAdd.metFormulas must be a cell array of strings');
   end
   %Add empty field if it doesn't exist
   if ~isfield(newModel,'metFormulas')
        newModel.metFormulas=largeFiller;
   end
   newModel.metFormulas=[newModel.metFormulas;metsToAdd.metFormulas(:)];
else
    %Add default
    if isfield(newModel,'metFormulas')
       newModel.metFormulas=[newModel.metFormulas;filler]; 
    end
end

%Don't check the type of metMiriams
if isfield(metsToAdd,'metMiriams')
   if numel(metsToAdd.metMiriams)~=nMets
       dispEM('metsToAdd.metMiriams must have the same number of elements as metsToAdd.mets');
   end
   %Add empty field if it doesn't exist
   if ~isfield(newModel,'metMiriams')
        newModel.metMiriams=cell(nOldMets,1);
   end
   newModel.metMiriams=[newModel.metMiriams;metsToAdd.metMiriams(:)]; 
else
    if isfield(newModel,'metMiriams')
       newModel.metMiriams=[newModel.metMiriams;cell(nMets,1)]; 
    end
end

if isfield(newModel,'metFrom')
    newModel.metFrom=[newModel.metFrom;filler];
end

%Expand the S matrix
newModel.S=[newModel.S;sparse(nMets,size(newModel.S,2))];

if copyInfo==true
   [I J]=ismember(metsToAdd.metNames,model.metNames);
   J=J(I);
   %I is the indexes of the new metabolites for which a metabolite with the
   %same name existed
   I=find(I)+nOldMets;
   %Go through each of the added mets and copy annotation if it doesn't exist
   for i=1:numel(I)
       if isfield(newModel,'inchis')
           if isempty(newModel.inchis{I(i)})
               newModel.inchis(I(i))=newModel.inchis(J(i));
           end
       end
       if isfield(newModel,'metFormulas')
           if isempty(newModel.metFormulas{I(i)})
               newModel.metFormulas(I(i))=newModel.metFormulas(J(i));
           end
       end
       if isfield(newModel,'metMiriams')
           if isempty(newModel.metMiriams{I(i)})
               newModel.metMiriams(I(i))=newModel.metMiriams(J(i));
           end
       end
   end
end
end
%For getting the numerical form of metabolite ids on the form "m1".
function I=getInteger(s)
    %Checks if a string is on the form "m1" and if so returns the value of
    %the integer
    I=0;
    if strcmpi(s(1),'m')
        t=str2double(s(2:end));
        if ~isnan(t) && ~isempty(t)
            I=t;
        end
    end
end