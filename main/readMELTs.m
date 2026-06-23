% May 20th, 2026
% # read the output file of MELTs
% # Input
% filepath - [char/string] file path of the output file *.out
% (optional)
% MELTsMode - [char] {'Fractionate','Equilibrate'}
% # Output
% state - [struct] T, P, log10fO2 and redox mode
% liquid - [struct] compositional and physical evolution of melts
% mineraldata - [struct] evolution of minerals
% filename.csv - fraction evolution of melt and mienral with T, P
% (optional)
% filename-detail.csv - compositional variations of chosen minerals

function [state,liquid,mineraldata]=readMELTs(filepath,opts)

arguments
    filepath {mustBeFile mustbeMELTs}
    opts.MELTsMode char {mustBeMember(opts.MELTsMode,...
        {'Fractionate','Equilibrate'})} = 'Fractionate'
    opts.mineral string {mustBeMember(opts.mineral,...
        ["olivine","garnet","clinopyroxene","orthopyroxene",...
    "amphibole","biotite","muscovite","feldspar","quartz","leucite",...
    "sillimanite","rhmoxide","whitlockite","spinel","fluid"])} = []
end

file=fopen(filepath);
[~,filename]=fileparts(filepath); % Output sheet
filename=char(filename);
detailmine=opts.mineral;
switch opts.MELTsMode
    case 'Fractionate'
        statestep = 39; endstep = 5;
    case 'Equilibrate'
        statestep = 37; endstep = 4;
end

liquidfieldname = ["SiO2","TiO2","Al2O3","Fe2O3","Cr2O3","FeO","MnO","MgO",...
    "NiO","CoO","CaO","Na2O","K2O","P2O5","H2O","CO2","SO3","Cl2O","F2O"];
for i=1:numel(liquidfieldname), liquid.CompName(i)=liquidfieldname(i); end

mineralcheckname = ["olivine","garnet","clinopyroxene","orthopyroxene",...
    "amphibole","biotite","muscovite","feldspar","quartz","leucite",...
    "sillimanite","rhm-oxide","whitlockite","spinel","apatite","fluid"];

for i=1:numel(mineralcheckname)
    mineralfieldname=legalfieldname(char(mineralcheckname(i)));
    mineraldata.(mineralfieldname)=Minerals;
    mineraldata.(mineralfieldname).Name=mineralcheckname(i);
    mineraldata.(mineralfieldname)=initminerals(mineraldata.(mineralfieldname));
end
clearvars mineralfieldname


cblock=textscan(file,'%s',1);
cnt = 1; % Counts for the whole loop

while ~isempty(cblock{1})
    
tblock=textscan(file,'%s',statestep); % temporal block
if cnt==1, state.RedoxBuffer=string(tblock{1}{37}); end
state.Tpath(cnt,1)=double(string(tblock{1}{5})); % (˚C)
state.Ppath(cnt,1)=double(string(tblock{1}{9})); % (kbar)
state.lgfO2path(cnt,1)=double(string(tblock{1}{15})); 

% Liquid %-----------------------------------------------------------------
textscan(file,'%s',1); tblock=textscan(file,'%s',11); % Liquid Parameter
liquid.Fraction(cnt,1)=double(string(tblock{1}{3})); % Mass fraction
liquid.Density(cnt,1)=double(string(tblock{1}{7})); % g/cm^3
liquid.Viscosity(cnt,1)=double(string(tblock{1}{11})); % log10 poise
% Liquid content
textscan(file,'%*[^\n]',2); textscan(file,'%s',19);
tblock=textscan(file,'%s',19);
for i=1:19
    liquid.Composition(cnt,i)=double(string(tblock{1}{i}));
end

% Minerals %---------------------------------------------------------------
tblock=textscan(file,'%s',1); 
while ~isequal(tblock{1}{1},'Summary'), tblock=textscan(file,'%s',1); end
textscan(file,'%s',9); tblock=textscan(file,'%s',1);
minenum=0;
while ~isequal(tblock{1}{1},'Viscosity')
    minename=string(tblock{1}{1});
    minename=legalfieldname(char(minename));
    if isempty(mineraldata.(minename).Fraction), minenum=minenum+1; end
    tblock=textscan(file,'%s%s%f%s',1);
    mineraldata.(minename).Fraction(cnt,1)=tblock{3};
    tblock=textscan(file,'%s%s%f%s',1);
    mineraldata.(minename).Density=tblock{3};
    textscan(file,'%*[^\n]',1);
    tblock=textscan(file,'%s',mineraldata.(minename).Length);
    comp=tblock{1}{end};
    elelen=0;
    for eleidx=1:numel(mineraldata.(minename).Elecheck)
        elelen=elelen+length(char(mineraldata.(minename).Elecheck(eleidx)));
        elecomp=double(string(comp((elelen+1):(elelen+4))))*mineraldata.(minename).Rate(eleidx);
        mineraldata.(minename).EleComp(cnt,eleidx)=elecomp;
        elelen=elelen+4;
    end
    textscan(file,'%*[^\n]',mineraldata.(minename).Space);
    tblock=textscan(file,'%s',1);
    
end

textscan(file,'%*[^\n]',endstep);
cnt=cnt+1;
cblock=textscan(file,'%s',1);
end
fclose(file);
clearvars cblock tblock statestep endstep comp elelen elecomp

sheetminefrac=nan(cnt-1,minenum); minefracname=strings(1,minenum);
minecnt=0;
for i=1:numel(mineralcheckname)
    minename=legalfieldname(char(mineralcheckname(i)));
    mineraldata.(minename)=Minerals.calcOxidComp(mineraldata.(minename));
    if mineraldata.(minename).isMgNum==1
        mineraldata.(minename)=Minerals.calcMgNum(mineraldata.(minename));
    end
    if ~isempty(mineraldata.(minename).Fraction)
        minecnt=minecnt+1;
        sheetminefrac(:,minecnt)=mineraldata.(minename).Fraction;
        minefracname(minecnt)=string(minename);
    end
end
clearvars minecnt

sheetcont=[state.Tpath,state.Ppath,state.lgfO2path,repmat(state.RedoxBuffer,size(state.Tpath)),...
    liquid.Composition,liquid.Fraction,sheetminefrac,sum(sheetminefrac,2)];
Varname=["T (C)","P (kbar)","log10fO2","RedoxMode",liquid.CompName,"Melts",minefracname,"Minerals"];
output=array2table(sheetcont,'VariableNames',Varname);
writetable(output,['../Output/' filename '.csv']);
disp('------------Output:------------'); disp([filename '.csv']);
clearvars sheetcont Varname output

if isempty(detailmine)
    if exist([filename '-detail.csv'],'file')
        fid=fopen([filename '-detail.csv'],'w'); fclose(fid);
    end
    return
end

twid = 0;
for i=1:numel(detailmine)
    twid=twid+width(mineraldata.(detailmine(i)).OxidComp); 
    if mineraldata.(detailmine(i)).isMgNum==1, twid=twid+1; end
end
twid=twid+4+numel(detailmine);
sheetcont=strings(cnt-1,twid); Varname=strings(1,twid);
sheetcont(:,1:4)=[state.Tpath,state.Ppath,state.lgfO2path,repmat(state.RedoxBuffer,size(state.Tpath))];
Varname(1:4)=["T (C)","P (kbar)","log10fO2","RedoxMode"];
clearvars twid
widcnt=5;
for i=1:numel(detailmine)
    sheetcont(:,widcnt:widcnt+width(mineraldata.(detailmine(i)).OxidComp))=...
        [mineraldata.(detailmine(i)).Fraction,mineraldata.(detailmine(i)).OxidComp];
    Varname(widcnt:widcnt+width(mineraldata.(detailmine(i)).OxidComp))=...
        [mineraldata.(detailmine(i)).Name,mineraldata.(detailmine(i)).OxidName+"-"+num2str(i)];
    widcnt=widcnt+width(mineraldata.(detailmine(i)).OxidComp)+1;
    if mineraldata.(detailmine(i)).isMgNum==1
        sheetcont(:,widcnt)=mineraldata.(detailmine(i)).MgNum;
        Varname(widcnt)="Mg#"+"-"+num2str(i);
        widcnt=widcnt+1;
    end
end
output=array2table(sheetcont,'VariableNames',Varname);
writetable(output,['../Output/' filename '-detail.csv'])
disp([filename '-detail.csv']);
end
% =====
function mustbeMELTs(filepath)
[~,~,ext]=fileparts(filepath);
if ~isequal(ext,'.out'), error('Wrong File: Not MELTs results'); end
end
% %---
function newfieldname=legalfieldname(fieldname)
illegal='.()-';
mask=ismember(fieldname,illegal); illegalidx=find(mask);
newfieldname=fieldname;
if ~isempty(illegalidx), newfieldname(illegalidx)=[]; end
end
% %----
function mineraldata=initminerals(mineraldata)

arguments, mineraldata Minerals; end

switch mineraldata.Name

    case "olivine" % (Ca,Mg,Fe'',Mn,Co,Ni)2SiO4
        mineraldata.MassBase=28.09+16*4;
        mineraldata.Length=1;
        mineraldata.Elecheck=["(Ca","Mg","Fe__","Mn","Co","Ni"];
        mineraldata.ElementMass=[40.08,24.31,55.85,54.94,58.93,58.69];
        mineraldata.OxidMVal=2*ones(size(mineraldata.Elecheck));
        mineraldata.OxidName=["CaO","MgO","FeO","MnO","CoO","NiO"];
        mineraldata.Rate=[2,2,2,2,2,2];
        mineraldata.Space=3;
        mineraldata.isMgNum=true;
        mineraldata.MgNum=NaN;
        disp('# Olivine Load')

    case "clinopyroxene" % cpx Na,Ca,Fe'',Mg,Fe''',Ti,Al,Si,O6
        mineraldata.MassBase=6*16;   
        mineraldata.Length=2;
        mineraldata.Elecheck=["Na","Ca","Fe__","Mg","Fe___","Ti","Al","Si"];
        mineraldata.ElementMass=[22.99,40.08,55.85,24.31,55.85,47.87,26.98,28.09];
        mineraldata.OxidMVal=[1,2,2,2,3,4,3,4];
        mineraldata.OxidName=["Na2O","CaO","FeO","MgO","Fe2O3","TiO2","Al2O3","SiO2"];
        mineraldata.Rate=ones(size(mineraldata.Elecheck));
        mineraldata.Space=3;
        mineraldata.isMgNum=true;
        mineraldata.MgNum=NaN;
        disp('# Clinopyroxene Load')

    case "spinel" % Fe'',Mg,Fe''',Al,Cr,Ti,O4
        mineraldata.MassBase=16*4;
        mineraldata.Length=1;
        mineraldata.Elecheck=["Fe__","Mg","Fe___","Al","Cr","Ti"];
        mineraldata.ElementMass=[55.85,24.31,55.85,26.98,52.00,47.87];
        mineraldata.OxidMVal=[2,2,3,3,2,4];
        mineraldata.Rate=ones(size(mineraldata.Elecheck));
        mineraldata.Space=3;
        mineraldata.isMgNum=true;
        mineraldata.MgNum=NaN;
        disp('# Spinel Load')
        
    case "feldspar" % K,Na,Ca,Al,Si,O8
        mineraldata.MassBase=16*8;
        mineraldata.Length=1;
        mineraldata.Elecheck=["K","Na","Ca","Al","Si"];
        mineraldata.ElementMass=[39.10,22.99,40.08,26.98,28.09];
        mineraldata.OxidMVal=[1,1,2,3,4];
        mineraldata.Rate=ones(size(mineraldata.Elecheck));
        mineraldata.Space=3;
        mineraldata.isMgNum=false;
        mineraldata.MgNum=NaN;
        disp('# Feldspar Load')

    case "quartz" % SiO2
        mineraldata.MassBase=28.09+16*2;
        mineraldata.Length=1;
        mineraldata.Space=1;
        mineraldata.isMgNum=false;
        disp('# Quartz Load')

    case "rhm-oxide" % Mn,Fe'',Mg,Fe''',Ti,O3
        mineraldata.MassBase=16*3;
        mineraldata.Length=1;
        mineraldata.Elecheck=["Mn","Fe__","Mg","Fe___","Ti"];
        mineraldata.ElementMass=[54.94,55.85,24.31,55.85,47.87];
        mineraldata.OxidMVal=[2,2,2,3,4];
        mineraldata.Rate=ones(size(mineraldata.Elecheck));
        mineraldata.Space=3;
        mineraldata.isMgNum=true;
        disp('# Rhm-oxide Load')

    case "apatite" % Ca5(PO4)3OH
        mineraldata.MassBase=NaN;
        mineraldata.Length=1;
        mineraldata.Space=1;
        mineraldata.isMgNum=false;
        disp('# Apatite Load')
end

end