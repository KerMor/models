classdef KernelTest < models.BaseFullModel & models.BaseDynSystem & dscomponents.CompwiseKernelCoreFun
    % Kernel core function test model 1
    %
    % This class implements both the model and dynamical system!
    %
    
    properties
        % The system's dimension
        dim;
        
        % SV's
        svNum;
    end
    
    methods
        
        function this = KernelTest(dims, pos_flag)
            
            if nargin < 2
                pos_flag = false;
                if nargin < 1
                    dims = 1000;
                end
            end
            this.dim = dims;
            
            %% Model settings
            this.Name = 'Test model';
            
            this.T = 5;
            this.dt = .08;
            
            this.Sampler = [];%sampling.GridSampler;
            
            % This class implements a fake Approx subclass to allow access
            % to the this.Ma property for the error estimator.
            this.Approx = [];
            
            s = spacereduction.PODReducer;
            s.UseSVDS = true;
            s.Mode = 'abs';
            s.Value = 1;
            this.SpaceReducer = s;
            
            %this.ODESolver = solvers.MLWrapper(@ode45);
            this.ODESolver = solvers.ExplEuler;
            %this.ODESolver = solvers.Heun;
            
            %% System settings
            this.System = this;
            
            this.x0 = @(mu)ones(dims,1)*.5;
            
            this.f = this;
            
            %this.Inputs{1} = @(t)0;
            
            % Sample bases
            this.svNum = 20;
            this.Centers.xi = repmat(linspace(-24,24,this.svNum),this.dim,1);
            %this.Centers.xi = linspace(-20,20,this.svNum);
            this.Centers.ti = [];
            this.Centers.mui = [];
            
            % Function coefficients
            offset = .5;
            %offset = 0;
            if pos_flag
                offset = 0;
            end
            ai = (rand(1,this.svNum)-offset);
            
            this.Ma = repmat(ai,dims,1);
            
            %% BaseCompWiseKernelApprox settings
            %this.SystemKernel = kernels.GaussKernel(4*sqrt(dims));
            this.SystemKernel = kernels.GaussKernel(40*dims);
            this.TimeKernel = kernels.NoKernel;
            this.ParamKernel = kernels.NoKernel;
        end
        
%         function copy = clone(this)
%             copy = models.synth.KernelTest;
%         end
        
%         function proj = project(this, V, W)
%             proj = project@dscomponents.CompwiseKernelCoreFun(this, V, W);
%             if this.RotationInvariant
%                 proj.Centers.xi = W' * proj.Centers.xi;
%             end
%         end
        
        function c = getcfi(this, z, C, t, mu)
            C = 100;
            di = this.xi - repmat(this.Data.V*z,1,this.sv);
            di = sqrt(sum(di.^2));
            case1 = di - C >= 0;
            case2 = ~case1;
            b = this.sk.Gamma;
            t2 = exp(-((di+C).^2/b));
            ci(case1) = (exp(-(di(case1)-C).^2/b) - t2(case1));
            ci(case2) = (1 - t2(case2));
            c = this.Ma_norms*ci';
        end
        
        function showBaseFun(this)
            % Debug method; displays the core function for each parameter
            % sample.
            figure;
            x = repmat(linspace(-50,50,max(this.svNum*5,100)),this.dim,1);
            fx = this.evaluate(x,0,[]);
            plot(x(1,:),fx(1,:),'r');
            xlabel('x'); ylabel('f(x)');
            title('KernelTest base function');
        end
        
    end
    
    methods (Static, Access=protected)
        function obj = loadobj(s)
            % Loads the properties for the BaseFullModel part of this
            % class.
            %
            % See also: ILoadable BaseFullModel.loadobj
            obj = models.synth.KernelTest;
            
            obj = loadobj@models.BaseFullModel(s, obj);
            obj.dim = s.dim;
            obj.svNum = s.svNum;
        end
    end
    
    methods(Static)
        
        function r = runTest(model)
            model.offlineGenerations;
            r = model.buildReducedModel;
            r.analyze;
        end
        
        function m = getTest1(varargin)
            m = models.synth.KernelTest(varargin{:});
            
            V = ones(m.dim,1)*sqrt(1/m.dim);
            m.SpaceReducer = spacereduction.ManualReduction(V);
        end
        
        function m = getTest2(varargin)
            m = models.synth.KernelTest(varargin{:});
            
            m.System.Inputs{1} = @(t)4;
            m.System.B = dscomponents.LinearInputConv(ones(m.dim,1));
            
            V = ones(m.dim,1)*sqrt(1/m.dim);
            m.SpaceReducer = spacereduction.ManualReduction(V);
        end
        
        function m = getTest3(varargin)
            m = models.synth.KernelTest(varargin{:});
            
            x0 = rand(m.dim,1);
            m.System.x0 = @(mu)x0;
        end
        
        function m = getTest4(varargin)
            m = models.synth.KernelTest(varargin{:});
            
            x0 = rand(m.dim,1);
            m.System.x0 = @(mu)x0;
            V = ones(m.dim,1)*sqrt(1/m.dim);
            m.SpaceReducer = spacereduction.ManualReduction(V);
        end
        
        function m = getTest5(varargin)
            m = models.synth.KernelTest(varargin{:});
            
            m.System.B = dscomponents.LinearInputConv(rand(m.dim,1));
            m.System.Inputs{1} = @(t)4;
        end
        
        function m = getTest6(varargin)
            m = models.synth.KernelTest(varargin{:});
            
            m.System.B = dscomponents.LinearInputConv(rand(m.dim,1));
            m.System.Inputs{1} = @(t)4;
            
            V = ones(m.dim,1)*sqrt(1/m.dim);
            m.SpaceReducer = spacereduction.ManualReduction(V);
        end
        
        function m = getTest7(varargin)
            m = models.synth.KernelTest(varargin{:});
            
            m.System.Inputs{1} = @(t)4;
            
            B = ones(m.dim,1);
            B(1:m.dim/2) = -1;
            m.System.B = dscomponents.LinearInputConv(B);
        end
        
        function m = getTest8(varargin)
            m = models.synth.KernelTest(varargin{:});
            
            m.System.Inputs{1} = @(t)4;
            
            B = ones(m.dim,1);
            B(1:m.dim/2) = -1;
            m.System.B = dscomponents.LinearInputConv(B);
            
            V = ones(m.dim,1)*sqrt(1/m.dim);
            m.SpaceReducer = spacereduction.ManualReduction(V);
        end
        
        function m = getTest9(varargin)
            m = models.synth.KernelTest(varargin{:});
            
            m.System.Inputs{1} = @(t)4;
            
            x0 = (rand(m.dim,1)-.5)*3;
            m.System.x0 = @(mu)x0;
            
            B = ones(m.dim,1);
            B(1:m.dim/2) = -1;
            m.System.B = dscomponents.LinearInputConv(B);
            
            V = ones(m.dim,1)*sqrt(1/m.dim);
            m.SpaceReducer = spacereduction.ManualReduction(V);
        end
        
        function m = getTest10(varargin)
            m = models.synth.KernelTest(varargin{:});
            m.T = 20;
            
            m.System.Inputs{1} = @(t)sin(2*t);
            
            x0 = (rand(m.dim,1)-.5)*3;
            m.System.x0 = @(mu)x0;
            
            B = ones(m.dim,1);
            B(1:m.dim/2) = -1;
            m.System.B = dscomponents.LinearInputConv(B);
            
            V = ones(m.dim,1)*sqrt(1/m.dim);
            m.SpaceReducer = spacereduction.ManualReduction(V);
        end
        
        function m = getTest11(varargin)
            m = models.synth.KernelTest(varargin{:});
            m.T = 20;
            
            m.System.B = dscomponents.LinearInputConv(rand(m.dim,1));
            m.System.Inputs{1} = @(t)sin(2*t);
        end
    end
    
end
