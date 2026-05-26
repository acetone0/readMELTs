function minerals=upgrade_minerals

disp('Updrading mineral information...')
%olivine (Ca,Mg,Fe'',Mn,Co,Ni)2SiO4
olivine=def_mineral;
olivine.name='olivine';
olivine.mass=28.09+16*4;
olivine.length=1;
olivine.element=["(Ca","Mg","Fe__","Mn","Co","Ni"];
olivine.element_mass=[40.08,24.31,55.85,54.94,58.93,58.69];
olivine.rate=[2,2,2,2,2,2];
olivine.content=zeros(1,numel(olivine.element));
olivine.check_Mg_=1;
olivine.Mg_=-1;
disp('# Ol Done')

%clinopyroxene cpx Na,Ca,Fe'',Mg,Fe''',Ti,Al,Si,O6
cpx=mineral_inf;
cpx.name='clinopyroxene';
cpx.mass=6*16;
cpx.length=2;
cpx.element=["Na","Ca","Fe__","Mg","Fe___","Ti","Al","Si"];
cpx.element_mass=[22.99,40.08,55.85,24.31,55.85,47.87,26.98,28.09];
cpx.rate=ones(size(cpx.element));
cpx.content=zeros(1,numel(cpx.element));
cpx.check_Mg_=1;
cpx.Mg_=-1;
disp('# Cpx Done')

minerals=[olivine,cpx];
