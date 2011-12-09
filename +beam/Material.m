classdef Material < handle
% Material: 
%
%
%
% @author Christoph Strohmeyer @date 2011-12-06
%
% @new{0,6,CS,2011-12-06} Added this class.
%
% This class is part of the framework
% KerMor - Model Order Reduction using Kernels:
% - \c Homepage http://www.agh.ians.uni-stuttgart.de/research/software/kermor.html
% - \c Documentation http://www.agh.ians.uni-stuttgart.de/documentation/kermor/
% - \c License @ref licensing
    
    properties
        % Au�endurchmesser (m)
        d_a = 457e-3;
        % Wandst�rke (m)
        s = 40e-3;
        % Isolierungsdicke (m)
        iso = 400e-3;
        % Manteldicke (m)
        mantel = 1e-3;
        % Dichte des Stahls (kg/m�) (Konstruktor!)
        rho;
        % Dichte der Isolierung (kg/m�)
        rho_iso = 100;
        % Dichte des Mantels (kg/m�)
        rho_mantel = 7850;
        % Dichte des Mediums (kg/m�)
        rho_med = 20;
        % Querkontraktionszahl
        ny = 0.3;
        % E-Modul (N/m�) (Konstruktor!)
        E;
        % Rohrinnendruck (N/m�)
        p = 50 * 1e5;
    end
    
    properties(SetAccess = protected)
        A;
        Iy;
        Iz;
        It;
        G;
        k;
        q_plus;
    end
    
    methods
        function this = Material(rho, E)
            % @todo q_pkus in effektive dichte umrechnen
            this.rho = rho;
            this.E = E;
            
            % Innen-/Au�endurchmesser des Rohrs
            r_a = 0.5 * this.d_a;
            r_i = r_a - this.s;
            % Querschnittsfl�che f�r Balken
            this.A = pi * ( r_a^2 - r_i^2 );
            % Fl�chentr�gheitsmoment f�r Balken
            this.Iy = 0.25 * pi * ( r_a^4 - r_i^4 );
            this.Iz = this.Iy;
            
            % Torsionstr�gheitsmoment f�r Balken
            this.It = 2 * Iy;
            % Schubmodul f�r Balken
            this.G = E / ( 2*(1+this.ny) );
            % Schubkorrekturfaktor f�r Balken
            m_tmp = r_i / r_a;
            this.k = 6*(1+this.ny)*(1+m_tmp^2)^2 / ( (7+6*this.ny)*(1+m_tmp^2)^2 + (20+12*this.ny)*m_tmp^2);

            % Berechnung der durch Medium und D�mmung verursachten zus�tzlichen Steckenlast
            this.q_plus = pi * ( r_i^2 * this.rho_med + ( (r_a + this.iso)^2 - r_a^2 ) * this.rho_iso + ( (r_a + this.iso + this.mantel)^2 - (r_a + this.iso)^2) * this.rho_mantel );
        end
        
    end
    
end