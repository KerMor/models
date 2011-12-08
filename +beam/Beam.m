classdef Beam < models.beam.StructureElement
% Beam: 
%
%
%
% @author Daniel Wirtz @date 2011-12-05
%
% @new{0,6,dw,2011-12-05} Added this class.
%
% This class is part of the framework
% KerMor - Model Order Reduction using Kernels:
% - \c Homepage http://www.agh.ians.uni-stuttgart.de/research/software/kermor.html
% - \c Documentation http://www.agh.ians.uni-stuttgart.de/documentation/kermor/
% - \c License @ref licensing

    properties(Constant)
        % Au�endurchmesser (m)
        ROHR_d_a = 457e-3;
        
        % Wandst�rke (m)
        ROHR_s = 40e-3;
        
        % Isolierungsdicke (m)
        ROHR_iso = 400e-3;
        
        % Manteldicke (m)
        ROHR_mantel = 1e-3;
        
        % Dichte der Isolierung (kg/m�)
        ROHR_rho_iso = 100;
        
        % Dichte des Mantels (kg/m�)
        ROHR_rho_mantel = 7850;
        
        % Dichte des Mediums (kg/m�)
        ROHR_rho_med = 20;
        
        % Querkontraktionszahl
        ROHR_ny = 0.3;
        
        %% Abh�ngige konstanten
        
        % Innen-/Au�endurchmesser des Rohrs
        ROHR_r_a = 0.5 * models.beam.Beam.ROHR_d_a;
        
        % 
        ROHR_r_i = models.beam.Beam.ROHR_r_a - models.beam.Beam.ROHR_s;
        
        % Querschnittsfl�che f�r Balken
        ROHR_A = pi * ( models.beam.Beam.ROHR_r_a^2 - models.beam.Beam.ROHR_r_i^2 );
        
        % Fl�chentr�gheitsmoment f�r Balken
        ROHR_Iy = 0.25 * pi * ( models.beam.Beam.ROHR_r_a^4 - models.beam.Beam.ROHR_r_i^4 );
        
        % Torsionstr�gheitsmoment f�r Balken
        ROHR_It = 2 * models.beam.Beam.ROHR_Iy;
        
        % Schubkorrekturfaktor f�r Balken
        ROHR_k = 6*(1+models.beam.Beam.ROHR_ny)*(1+(models.beam.Beam.ROHR_r_i / models.beam.Beam.ROHR_r_a)^2)^2 /...
            ( (7+6*models.beam.Beam.ROHR_ny)*(1+(models.beam.Beam.ROHR_r_i / models.beam.Beam.ROHR_r_a)^2)^2 +...
            (20+12*models.beam.Beam.ROHR_ny)*(models.beam.Beam.ROHR_r_i / models.beam.Beam.ROHR_r_a)^2);
        
        % Berechnung der durch Medium und D�mmung verursachten zus�tzlichen Steckenlast
        ROHR_q_plus = pi * ( models.beam.Beam.ROHR_r_i^2 * models.beam.Beam.ROHR_rho_med + ( (models.beam.Beam.ROHR_r_a + models.beam.Beam.ROHR_iso)^2 ...
            - models.beam.Beam.ROHR_r_a^2 ) * models.beam.Beam.ROHR_rho_iso + ( (models.beam.Beam.ROHR_r_a + models.beam.Beam.ROHR_iso + models.beam.Beam.ROHR_mantel)^2 ...
            - (models.beam.Beam.ROHR_r_a + models.beam.Beam.ROHR_iso)^2) * models.beam.Beam.ROHR_rho_mantel );
    end
   
    properties
        % Speichert den anteil des jeweiligen Elements an der Gesamtsysteml�nge
        %
        % Siehe preprocess_data
        split;
        
        % Dichte des Stahls (kg/m�)(eingelesen!)
        ROHR_rho = [];
        
        % E-Modul (N/m�)(eingelesen!)
        ROHR_E = [];
    end
    
    properties(SetAccess=private)
        % Schubmodul f�r Balken
        ROHR_G;
    end
    
    methods
        function this = Beam(model, material, pointsidx)
            this = this@models.beam.StructureElement(model, material, pointsidx);
        end
    end
    
    methods(Access=protected)
        function initialize(this)
            this.ROHR_rho = this.Material(1);
            this.ROHR_E = this.Material(3);
            this.c_theta = this.Material(9);
            this.kappa = this.Material(10);
            this.alphaA = this.Material(11) * this.Material(2) * this.Material(3); % alpha*A*E
            
            % Schubmodul f�r Balken
            this.ROHR_G = this.ROHR_E / ( 2*(1+this.ROHR_ny) );
        end
    end
    
end