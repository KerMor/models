classdef AffParamKernelTest < models.BaseFullModel
    % Kernel core function test model 1
    %
    % This class implements both the model and dynamical system!
    %
    % @change{0,3,sa,2011-05-11} Implemented property setter
    %
    % This class is part of the framework
    % KerMor - Model Order Reduction using Kernels:
    % - \c Homepage http://www.morepas.org/software/index.html
    % - \c Documentation http://www.morepas.org/software/kermor/index.html
    % - \c License @ref licensing    
    
    properties(SetObservable)
        % The system's dimension
        %
        % @propclass{experimental} Test quantity.
        dim;
    end
    
    methods
        
        function this = AffParamKernelTest(dims, pos_flag)
            
            this.registerProps('dim');
            
            if nargin < 2
                pos_flag = false;
                if nargin < 1
                    dims = 1000;
                end
            end
            this.dim = dims;
            
            
            %% Model settings
            this.Name = 'Kernel test model';
            
            this.T = 5;
            this.dt = .08;
            
            this.Sampler = sampling.GridSampler;
            
            % This class implements a fake Approx subclass to allow access
            % to the this.Ma property for the error estimator.
            this.Approx = [];
            
            s = spacereduction.PODReducer;
            s.UseSVDS = true;
            s.Mode = 'abs';
            s.Value = 1;
            this.SpaceReducer = s;
            
            this.ODESolver = solvers.ExplEuler;
            
            %% System settings
            this.System = models.synth.AffParamKernelTestSys(this, pos_flag);
            this.DefaultInput = 1;
            this.TrainingInputs = 1;
            
            %% Error estimator
            this.ErrorEstimator = error.IterationCompLemmaEstimator;
        end
        
        function set.dim(this,value)
            if round(value) ~= value || ~isscalar(value) || value <= 0
                error('Value must be a positive integer scalar');
            end
            this.dim = value;
        end
    end
      
    methods(Static)
        
        function res = test_RunAffParamKernelTests
            t = [];
            for k=1:11
                eval(sprintf('t = models.synth.AffParamKernelTest.getTest%d;',k))
                fprintf('--------------- Running test getTest%d ---------------\n',k);
                models.synth.AffParamKernelTest.runTest(t);
            end
            res = true;
        end
        
        function r = runTest(model)
            model.offlineGenerations;
            r = model.buildReducedModel;
            ma = ModelAnalyzer(r);
            pm = ma.analyzeError;
            pm.LeaveOpen = true;
        end
        
        function m = getTest1(varargin)
            m = models.synth.AffParamKernelTest(varargin{:});
            
            V = ones(m.dim,1)*sqrt(1/m.dim);
            m.SpaceReducer = spacereduction.ManualReduction(V);
        end
        
        function m = getTest2(varargin)
            m = models.synth.AffParamKernelTest(varargin{:});
            
            m.System.Inputs{1} = @(t)4;
            m.System.B = dscomponents.LinearInputConv(ones(m.dim,1));
            
            V = ones(m.dim,1)*sqrt(1/m.dim);
            m.SpaceReducer = spacereduction.ManualReduction(V);
        end
        
        function m = getTest3(varargin)
            m = models.synth.AffParamKernelTest(varargin{:});
            m.System.x0 = dscomponents.ConstInitialValue(rand(m.dim,1));
        end
        
        function m = getTest4(varargin)
            m = models.synth.AffParamKernelTest(varargin{:});
            m.System.x0 = dscomponents.ConstInitialValue(rand(m.dim,1));
            V = ones(m.dim,1)*sqrt(1/m.dim);
            m.SpaceReducer = spacereduction.ManualReduction(V);
        end
        
        function m = getTest5(varargin)
            m = models.synth.AffParamKernelTest(varargin{:});
            
            m.System.B = dscomponents.LinearInputConv(rand(m.dim,1));
            m.System.Inputs{1} = @(t)4;
        end
        
        function m = getTest6(varargin)
            m = models.synth.AffParamKernelTest(varargin{:});
            
            m.System.B = dscomponents.LinearInputConv(rand(m.dim,1));
            m.System.Inputs{1} = @(t)4;
            
            V = ones(m.dim,1)*sqrt(1/m.dim);
            m.SpaceReducer = spacereduction.ManualReduction(V);
        end
        
        function m = getTest7(varargin)
            m = models.synth.AffParamKernelTest(varargin{:});
            
            m.System.Inputs{1} = @(t)4;
            
            B = ones(m.dim,1);
            B(1:m.dim/2) = -1;
            m.System.B = dscomponents.LinearInputConv(B);
        end
        
        function m = getTest8(varargin)
            m = models.synth.AffParamKernelTest(varargin{:});
            
            m.System.Inputs{1} = @(t)4;
            
            B = ones(m.dim,1);
            B(1:m.dim/2) = -1;
            m.System.B = dscomponents.LinearInputConv(B);
            
            V = ones(m.dim,1)*sqrt(1/m.dim);
            m.SpaceReducer = spacereduction.ManualReduction(V);
        end
        
        function m = getTest9(varargin)
            m = models.synth.AffParamKernelTest(varargin{:});
            
            m.System.Inputs{1} = @(t)4;
            
            m.System.x0 = dscomponents.ConstInitialValue((rand(m.dim,1)-.5)*3);
            
            B = ones(m.dim,1);
            B(1:m.dim/2) = -1;
            m.System.B = dscomponents.LinearInputConv(B);
            
            V = ones(m.dim,1)*sqrt(1/m.dim);
            m.SpaceReducer = spacereduction.ManualReduction(V);
        end
        
        function m = getTest10(varargin)
            m = models.synth.AffParamKernelTest(varargin{:});
            m.T = 20;
            
            m.System.Inputs{1} = @(t)sin(2*t);
            
            m.System.x0 = dscomponents.ConstInitialValue((rand(m.dim,1)-.5)*3);
            
            B = ones(m.dim,1);
            B(1:m.dim/2) = -1;
            m.System.B = dscomponents.LinearInputConv(B);
            
            V = ones(m.dim,1)*sqrt(1/m.dim);
            m.SpaceReducer = spacereduction.ManualReduction(V);
        end
        
        function m = getTest11(varargin)
            m = models.synth.AffParamKernelTest(varargin{:});
            m.T = 20;
            
            m.System.B = dscomponents.LinearInputConv(rand(m.dim,1));
            m.System.Inputs{1} = @(t)sin(2*t);
        end
    end
    
end

