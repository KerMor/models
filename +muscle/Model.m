classdef Model < models.BaseFullModel
    % Model: Model for a FEM-discretized muscle model
    %
    % The global time unit for this model is milliseconds [ms] and the
    % spatial quantities are in [mm]. Weight is in [g].
    % This results in pressure values of [MPa] and the forces K(u,v,w) are
    % measured in [N] (Newton).
    %
    % @author Daniel Wirtz @date 2012-11-22
    
    properties
        MuscleDensity = 1.1e-3; % [g/mm³] (1100kg/m³)
        
        % The plotter class for visualization
        Plotter;
    end
    
    properties(SetAccess=private)
        % Seed that can be used by random number generator instances in order to enable result
        % reproduction.
        % @type int @default 1
        RandSeed = 1;
        
        Config;
        
        Gravity = 9.80665e-3; % [mm/ms²]
    end
    
    properties(Dependent)
        Geo;
    end
    
    methods
        function this = Model(conf, basedir)
            if nargin < 2
                basedir = KerMor.App.DataDirectory;
                if nargin < 1
                    conf = Debug;
                end
            end
            % Creates a new muscle model
            name = sprintf('FEM Muscle model %s',class(conf));
            this = this@models.BaseFullModel(name);
            
            this.SaveTag = sprintf('musclemodel_%s',class(conf));
            this.Data = data.ModelData(this,basedir);
            
            this.System = models.muscle.System(this);
            % Sets DefaultMu
            this.initDefaultParameter;
            
            this.TrainingParams = [1 2];
            
            this.T = 10; % [ms]
            this.dt = .01; % [ms]
            s = solvers.MLode15i;
            % Use relatively coarse precision settings. This skips fine
            % oscillations but yields the correct long time results.
            s.RelTol = 1e-1;
            s.AbsTol = 1e-1;
            this.ODESolver = s;
            this.System.MaxTimestep = []; %model.dt;
            
            % MOR pre-setup.
            % If you assign a new SpaceReducer instance, dont forget to set
            % the TargetDimensions property accordingly (is now
            % automatically set within the configureModel base routine)
            %s = spacereduction.PODGreedy;
            %s.Eps = 1e-9;
            %s.MaxSubspaceSize = 500;
            s = spacereduction.PODReducer;
            s.IncludeInitialSpace = true;
            s.IncludeBSpan = true;
            s.Mode = 'abs';
            this.SpaceReducer = s;
            
            % Call the config-specific model configuration
            conf.configureModel(this);
            
            % Set the config to the model, triggering geometry related
            % pre-computations
            this.setConfig(conf);
            
            conf.configureModelFinal;
            
            %% Health tests
            % Propagate the current default param
            this.System.prepareSimulation(this.DefaultMu, this.DefaultInput);
            
%             fprintf('Running Jacobian health check..');
%             res = this.System.f.test_Jacobian;
%             fprintf('Done. Success=%d\n',res);
%             chk = this.Config.FEM.test_JacobiansDefaultGeo;
% %             chk = chk && this.Config.FEM.test_QuadraticBasisFun;
%             chk = chk && this.Config.PressureFEM.test_JacobiansDefaultGeo;
%             if ~chk
%                 error('Health tests failed!');
%             end
        end
        
        function [t,y] = simulateAndPlot(this, withResForce, varargin)
            if nargin < 2
                withResForce = true;
            end
            [t,y] = this.simulate(varargin{:});
            xargs = {};
            if (withResForce)
                [df,nf] = this.getResidualForces(t,y);
                xargs = {'NF',nf,'DF',df};
            end
            this.plot(t,y,xargs{:});
        end
        
        function [t, x, time, cache] = computeTrajectory(this, mu, inputidx)
            % Allows to also call prepareSimulation for any quantities set
            % by the AMuscleConfig class.
            this.Config.prepareSimulation(mu, inputidx);
            [t, x, time, cache] = computeTrajectory@models.BaseFullModel(this, mu, inputidx);
        end
        
        function t = getConfigTable(this, mu)
            if nargin < 2
                mu = this.DefaultMu;
            end
            f = this.System.f;
            t = PrintTable('Configuration of Model %s',this.Name);
            t.HasHeader = true;
            t.addRow('\rho_0', 'c_{10} [MPa]','c_{01} [MPa]','b_1 [MPa]','d_1 [-]','P_{max} [MPa]','\lambda_f^{opt}');
            t.addRow(this.MuscleDensity, mu(9),mu(10),mu(5),mu(6),mu(13),mu(14));
            t.Format = 'tex';
        end
        
        function pm = plotDiff(this, t, uvw1, uvw2, fac, varargin)
            if nargin < 5
                fac = 5;
            end
            x0 = this.System.getX0(this.System.mu);
            diff = repmat(x0,1,length(t)) + (uvw1-uvw2)*fac;
            pm = this.plot(t,diff,varargin{:});
        end
        
        function plotForceLengthCurve(this, mu, pm)
            if nargin < 3
                pm = PlotManager(false,2,2);
                pm.LeaveOpen = true;
                if nargin < 2
                    mu = this.DefaultMu;
                end
            end
            sys = this.System;
            f = sys.f;
            sys.prepareSimulation(mu,this.DefaultInput);
            this.Config.setForceLengthFun(f);
            
            lambda = .2:.005:2;
            
            %% Plain Force-length function
            fl = f.ForceLengthFun(lambda);
            h = pm.nextPlot('force_length_plain','Direct force-length curve of muscle/sarcomere',...
                sprintf('\\lambda [-], fl_p1=%g',mu(14)),...
                'force-length relation [-]');
            plot(h,lambda,fl,'r');
            
            %% Effective force-length function for muscle tissue
            % effective signal from active part
            fl_eff = (mu(13)./lambda) .* fl;
            % Passive markert laws
            aniso_passive_muscle = f.AnisoPassiveMuscle(lambda);
            
            % Find a suitable position to stop plotting (otherwise the
            % passive part will steal the show)
            pos = find(aniso_passive_muscle > max(fl_eff)*1.4,1,'first');
            if ~isempty(pos)
                lambda = lambda(1:pos);
                fl_eff = fl_eff(1:pos);
                aniso_passive_muscle = aniso_passive_muscle(1:pos);
            end
            
            h = pm.nextPlot('force_length_eff',...
                'Effective force-length curve of muscle material',...
                '\lambda [-]','pressure [MPa]');
            plot(h,lambda,fl_eff,'r',lambda,aniso_passive_muscle,'g',lambda,fl_eff+aniso_passive_muscle,'b');
            legend(h,'Active','Passive','Total','Location','NorthWest');
            
%             %% Effective force-length function derivative for muscle tissue
%             dfl = (mu(13)./lambda) .* f.ForceLengthFunDeriv(lambda);
%             dmarkertf = (lambda>=1).*(b1./lambda.^3).*((d1-2)*lambda.^d1 + 2);
%             h = pm.nextPlot('force_length_eff_deriv',...
%                 'Effective force-length curve derivative of muscle material',...
%                 '\lambda','deriv [MPa/ms]');
%             plot(h,lambda,dfl,'r',lambda,dmarkertf,'g',lambda,dfl + dmarkertf,'b');
            
%             %% Cross fibre stuff
%             if this.System.UseCrossFibreStiffness
%                 error('fixme');
%                 markertf = max(0,(f.b1cf./lambda.^2).*(lambda.^f.d1cf-1));
%                 h = pm.nextPlot('force_length_xfibre',sprintf('Force-Length curve in cross-fibre direction for model %s',this.Name),'\lambda [-]','pressure [MPa]');
%                 plot(h,lambda,markertf,'r');
%                 axis(h,[0 2 0 150]);
%                 legend(h,'Passive cross-fibre pressure','Location','NorthWest');
%                 
%                 dmarkertf = (lambda >= 1).*(f.b1cf./lambda.^3).*((f.d1cf-2)*lambda.^f.d1cf + 2);
%                 h = pm.nextPlot('force_length_xfibre_deriv',sprintf('Derivative of Force-Length curve in cross-fibre direction for model %s',this.Name),'\lambda [-]','pressure [MPa]');
%                 plot(h,lambda,dmarkertf,'r');
%             end
            
            %% Passive force-length function for 100% tendon tissue
            % Passive markert law
            if sys.HasTendons
                aniso_passive_tendon = f.AnisoPassiveTendon(lambda);
                h = pm.nextPlot('force_length_tendon',...
                    'Effective force-length curve of tendon material (=passive)',...
                    '\lambda [-]','pressure [MPa]');
                plot(h,lambda,aniso_passive_tendon,'g');

                %% Effective force-length surface for muscle-tendon tissue
                % Sampled ratios
                tmr = 0:.03:1;
                %tmrlog = [0 logspace(-4,0,length(tmr)-1)];
                tmrlog = tmr;
                
                %% Passive part
                [LAM,TMR] = meshgrid(lambda,tmr);
                passive = repmat(aniso_passive_muscle,length(tmr),1) ...
                    + tmrlog'*(aniso_passive_tendon-aniso_passive_muscle);

                %% Active part
                FL = (1-tmr)'*fl_eff;

                %% Plot dat stuff!
                h = pm.nextPlot('force_length_muscle_tendon',...
                    'Effective force-length curve between muscle/tendon material',...
                    '\lambda [-]','muscle/tendon ratio [m=0,t=1]');
                surfc(LAM,TMR,passive+FL,'Parent',h,'EdgeColor','interp');
                zlabel('pressure [MPa]');
                zlim([0, 3*max(fl_eff(:))]);
            end
                
            if nargin < 2
                pm.done;
            end
        end
        
        function plotAnisotropicPressure(this, mu)
            if nargin < 2
                mu = this.DefaultMu;
            end
%             pm = PlotManager(false,1,2);
            pm = PlotManager;
            pm.LeaveOpen = true;
            f = this.System.f;
            
            warning('Using muscle parameters only (ignoring tendon)');
            
            [lambda, alpha] = meshgrid(.02:.02:1.5,0:.01:1);
            
            fl = f.ForceLengthFun(lambda/mu(14));
            active = mu(13)./lambda.*fl.*alpha;
            func = this.Config.getAnisoMuscleLaw(mu(5), mu(6));
            func = func.getFunction;
            passive = func(lambda);
            
            h = pm.nextPlot('aniso_pressure',sprintf('Pressure in fibre direction for model %s',this.Name),'Stretch \lambda','Activation \alpha');
            surf(h,lambda,alpha,active+passive,'EdgeColor','k','FaceColor','interp');
            
            pm.done;
        end
        
        function plotActivation(this)
            pm = PlotManager;
            pm.LeaveOpen = true;
            f = this.System.f;
            
            h = pm.nextPlot('activation',sprintf('Activation curve for model %s',this.Name),'time [ms]','alpha [-]');
            plot(h,this.Times,f.alpha(this.scaledTimes),'r');
            pm.done;
        end
        
        function plotPoolSignal(this)
            if ~isempty(this.Config.Pool)
                [a,all] = this.Config.Pool.getActivation(this.Times);
                figure;
                plot(this.Times,a,'r',this.Times,all,'g');
            end
        end
        
        function varargout = plotGeometrySetup(this, varargin)
            mu = this.System.mu;
            if isempty(mu)
                mu = this.DefaulMu;
            end
            this.System.prepareSimulation(mu, this.DefaultInput);
            if ~isempty(varargin) && isa(varargin{1},'PlotManager')
                varargin = [{'PM'} varargin];
            end
            i = inputParser;
            i.addParamValue('x0',[]);
            i.KeepUnmatched = true;
            i.parse(varargin{:});
            r = i.Results;
            if ~isempty(r.x0)
                x0 = r.x0;
            else
                x0 = this.System.getX0(this.System.mu);
            end
            [~, nf] = this.getResidualForces(0, x0);
            if ~isempty(nf)
                varargin(end+1:end+2) = {'NF',nf};
            end
            varargin(end+1:end+2) = {'Velo',true};
            %if ~isempty(this.Approx) && isa(this.System.f,'dscomponents.ACompEvalCoreFun') && ~isempty(this.System.f.PointSets)
            %    varargin(end+1:end+2) = {'DEIM',true};
            %end
            
            % Plot without default args (time-plotting might want to
            % suppress fibres for speed, but we want them here)
            old = this.Plotter.DefaultArgs;
            this.Plotter.DefaultArgs = {};
            [varargout{1:nargout}] = this.plot(0,x0,varargin{:});
            this.Plotter.DefaultArgs = old;
        end
        
        function plotGeometryInfo(this, varargin)
            this.Config.plotGeometryInfo(varargin{:});
        end
        
        function [residuals_dirichlet, residuals_neumann] = getResidualForces(this, t, uvw)
            sys = this.System;
            num_bc = length(sys.idx_u_bc_glob)+length(sys.idx_expl_v_bc_glob);
            residuals_dirichlet = zeros(num_bc,length(t));
            residuals_neumann = zeros(length(sys.idx_neumann_bc_glob),length(t));
            for k=1:length(t)
                dy = sys.f.evaluate(uvw(:,k),t(k));
                if ~isempty(residuals_neumann)
                    residuals_neumann(:,k) = dy(sys.idx_neumann_bc_dof);
                end
                residuals_dirichlet(:,k) = sys.f.LastBCResiduals;
            end
        end
        
        function idx = getFaceDofsGlobal(this, elem, faces, dim)
            % Returns the indices in the global uvw vector (including
            % dirichlet values) of the given faces in the given element.
            %
            % Parameters:
            % elem: The element index @type integer
            % faces: The faces whose indices to return. May also only be
            % one face. @type rowvec<integer>
            % dim: The dimensions which to select. @type rowvec<integer>
            % @default [1 2 3]
            %
            % Return values:
            % idx: The global indices of the face @type colvec<integer>
            if nargin < 4
                dim = 1:3;
            end
            geo = this.Config.FEM.Geometry;
            idxXYZ = false(3,geo.NumNodes);
            for k=1:length(faces)
                idxXYZ(dim,geo.Elements(elem,geo.MasterFaces(faces(k),:))) = true;
            end
            idx = find(idxXYZ(:));
        end
        
        function idx = getPositionDirichletBCFaceIdx(this, elem, face, dim)
            % Returns the positions of dofs of a specified face 
            % within the boundary conditions residual vector.
            % Applies to dirichlet boundary conditions of POSITION (u)
            %
            % Parameters:
            % elem: The element the face belongs to @type integer
            % face: The face number of that element @type integer
            % dim: Optionally, specify a requested dimension to get the
            % indices for. Defaults to return all x,y,z components on every
            % node on the face. @type rowvec<integer> @default 1:3
            if nargin < 4
                dim = 1:3;
            end
            geo = this.Config.FEM.Geometry;
            idx_face = false(size(this.System.bool_u_bc_nodes));
            idx_face(dim,geo.Elements(elem,geo.MasterFaces(face,:))) = true;
            fidx = find(this.System.bool_u_bc_nodes & idx_face);
            [~, idx] = intersect(this.System.idx_u_bc_glob, fidx);
        end
        
        function idx = getVelocityDirichletBCFaceIdx(this, elem, face, dim)
            % Returns the positions of dofs of a specified face 
            % within the boundary conditions residual vector.
            % Applies to dirichlet boundary conditions of VELOCITY (v)
            %
            % Parameters:
            % elem: The element the face belongs to @type integer
            % face: The face number of that element @type integer
            % dim: Optionally, specify a requested dimension to get the
            % indices for. Defaults to return all x,y,z components on every
            % node on the face. @type rowvec<integer> @default 1:3
            if nargin < 4
                dim = 1:3;
            end
            geo = this.Config.FEM.Geometry;
            idx_face = false(size(this.System.bool_u_bc_nodes));
            idx_face(dim,geo.Elements(elem,geo.MasterFaces(face,:))) = true;
            fidx = find(this.System.bool_expl_v_bc_nodes & idx_face);
            % Include the offset to the indices for velocity dofs
            fidx = fidx + geo.NumNodes*3;
            [~, idx] = intersect(this.System.idx_v_bc_glob, fidx);
            % Also include the offset of velocity components within the
            % dirichlet force vector
            idx = idx + length(this.System.val_u_bc);
        end
        
        function setConfig(this, value)
            if ~isa(value, 'models.muscle.AMuscleConfig')
                error('Config must be a models.muscle.AMuscleConfig instance');
            end
            this.Config = value;
            this.System.configUpdated;
            this.Plotter = models.muscle.MusclePlotter(this.System);
        end
        
        function setGaussIntegrationRule(this, value)
            % Sets the gauss integration rule for the model.
            % 
            % See fem.BaseFEM for possible values. Currently 3,4,5 are
            % implemented.
            mc = this.Config;
            mc.FEM.GaussPointRule = value;
            mc.PressureFEM.GaussPointRule = value;
            this.setConfig(mc);
            s = this.System;
            mu = s.mu;
            if isempty(mu)
                mu = this.DefaultMu;
            end
            in = s.inputidx;
            if isempty(in)
                in = this.DefaultInput;
            end
            s.prepareSimulation(mu,in);
        end
                
        function varargout = plot(this, varargin)
            [varargout{1:nargout}] = this.Plotter.plot(varargin{:});
        end
        
        function value = get.Geo(this)
            value = this.Config.Geometry;
        end
        
    end
    
    methods(Static)
        function res = test_ModelVersions
            res = true;
            try
                m = models.muscle.Model(models.muscle.examples.Debug);
                mu = m.getRandomParam;
                [t,y] = m.simulate(mu);
                m.System.UseDirectMassInversion = true;
                [t,y] = m.simulate(mu);

                % Version with "constant" fibre activation forces
                m = models.muscle.Model(models.muscle.examples.Debug(2));
                [t,y] = m.simulate(mu);
                m.System.UseDirectMassInversion = true;
                [t,y] = m.simulate(mu);

                % Version with "neurophysiological" fibre activation forces
                m = models.muscle.Model(models.muscle.examples.Debug(3));
                [t,y] = m.simulate(mu);
                m.System.UseDirectMassInversion = true;
                [t,y] = m.simulate(mu);
                m.System.UseDirectMassInversion = false;

                % "Disable" viscosity
                m.DefaultMu(1) = 0;
                [t,y] = m.simulate(mu);
                m.System.UseDirectMassInversion = true;
                [t,y] = m.simulate(mu);
            catch ME
                ME.getReport('extended')
                res = false;
            end
        end
        
        function res = test_JacobianApproxGaussRules
            % Tests the precision of the analytical jacobian computation
            % using different gauss integration rules
            m = models.muscle.Model(models.muscle.examples.Debug(2));
            m.simulate;
            f = m.System.f;
            m.dt = .2;
            m.T = 1;
            res = f.test_Jacobian;
            m.setGaussIntegrationRule(4);
            res = res && f.test_Jacobian;
            m.setGaussIntegrationRule(5);
            res = res && f.test_Jacobian;
        end
    end
    
    methods(Static, Access=protected)
        function this = loadobj(this)
            if ~isa(this, 'models.muscle.Model')
                sobj = this;
                this = models.muscle.Model;
                this.RandSeed = sobj.RandSeed;
                this.Config = sobj.Config;
                this = loadobj@models.BaseFullModel(this, sobj);
            else
                this = loadobj@models.BaseFullModel(this);
            end
        end
    end
end