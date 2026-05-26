classdef Minerals
    properties
        Name %{mustBeNonzeroLengthText}
        Fraction            % mass fraction (wt%) in melts
        Density             % density (g/cm^3)
        Length              % length of the context, 
        % e.g., cpx Na0.00Ca0.70Fe''0.44Mg0.79Fe'''0.01Ti0.02Al0.12Si1.92O6
        Mass                % mole mass of the mineral, default - invariable element mass
        MassBase
        Elecheck            % element in the mineral except constant (for upgrades)
        ElementMass         % molar mass of the element
        Rate                % rate of the mineral
        EleComp             % element content in the mineral
        OxidMVal            % chemical valence
        OxidComp            % oxide composition in the mineral (wt%)
        OxidName            % type of oxide
        Space               % line space in .out file
        isMgNum
        MgNum
    end
    
    methods (Static)
        function mineral=calcOxidComp(mineral)
            if isempty(mineral.EleComp), return; end
            mineral.Mass=mineral.MassBase+sum(mineral.ElementMass.*mineral.EleComp,2);
            mineral.OxidComp=mineral.EleComp./(mod(mineral.OxidMVal,2)+1).*...
                (mineral.ElementMass+mineral.OxidMVal/2*16)./mineral.Mass;
            if mineral.Name=="olivine"
                mineral.OxidComp=[mineral.OxidComp,1-sum(mineral.OxidComp,2)];
                mineral.OxidName=[mineral.OxidName,"SiO2"];
            end
        end

        function mineral=calcMgNum(mineral)
            if isempty(mineral.EleComp), return; end
            Mg=mineral.EleComp(:,mineral.Elecheck=="Mg");
            Fe2=0; Fe3=0;
            if ismember("Fe__",mineral.Elecheck)
                Fe2=mineral.EleComp(:,mineral.Elecheck=="Fe__");
            end
            if ismember("Fe___",mineral.Elecheck)
                Fe3=mineral.EleComp(:,mineral.Elecheck=="Fe___");
            end
            mineral.MgNum=Mg./(Mg+Fe2+Fe3)*100;
        end
    end
end
