classdef Tests
% Tests: Some tests and simulation settings for Burger's equation models.
%
%
%
% @author Daniel Wirtz @date 2012-06-13
%
% @new{0,6,dw,2012-06-13} Added this class.
%
% This class is part of the framework
% KerMor - Model Order Reduction using Kernels:
% - \c Homepage http://www.agh.ians.uni-stuttgart.de/research/software/kermor.html
% - \c Documentation http://www.agh.ians.uni-stuttgart.de/documentation/kermor/
% - \c License @ref licensing
    
    methods(Static)
        function createSorensenPlots
            d = fullfile(KerMor.App.DataStoreDirectory,'test_Burgers_DEIM_B');
            
            %m = models.burgers.Tests.test_Burgers_DEIM_B(100);
            load(fullfile(d,'test_Burgers_DEIM_B_d100.mat'));
            
            d = fullfile(KerMor.App.DataStoreDirectory,'test_Burgers_DEIM_B');
            
            m.Approx.Order = [6 5];
            r = m.buildReducedModel;
            
            mu = .04;
%             types = {'fig','pdf','jpg'};
%             types = {'png','jpg'};
            types = {'jpg'};
            
            pm = tools.PlotManager;
            pm.NoTitlesOnSave = true;
            pm.SingleSize = [720 540];
%             pm.MaxLegendRows = 5;
            pm.LeaveOpen = false;
            pm.UseFileTypeFolders = true;
            
            %% Simulation pics
%             m.PlotAzEl = [-49 34];
%             [~,y] = m.simulate(mu, 1);
%             [~,y1] = m.simulate(m.Data.ParamSamples(:,1), 1);
%             [~,y2] = m.simulate(m.Data.ParamSamples(:,end), 1);
%             r.ErrorEstimator.Enabled = false;
%             [t,yr] = r.simulate(mu, 1);
%             r.ErrorEstimator.Enabled = true;
%             
%             pm.FilePrefix = 'sim';
%             m.plot(t, y1, pm.nextPlot('full_sol_mumin',...
%                 sprintf('Full solution for \\mu=%g',m.Data.ParamSamples(:,1))));
%             
%             m.plot(t, y2, pm.nextPlot('full_sol_mumax',...
%                 sprintf('Full solution for \\mu=%g',m.Data.ParamSamples(:,end))));
%             %view(-24,44);
%             m.plot(t, y1-y2, pm.nextPlot('full_sol_muvar',...
%                 sprintf('Model variance over parameter range [%g, %g]',...
%                 m.Data.ParamSamples(:,1),m.Data.ParamSamples(:,end))));
%             %view(-26,22);
%             m.plot(t, y, pm.nextPlot('full_sol',...
%                 sprintf('Full solution for \\mu=%g',mu)));
%             m.plot(t, y, pm.nextPlot('red_sol',...
%                 sprintf('Reduced solution for \\mu=%g',mu)));
%             m.plot(t, y-yr, pm.nextPlot('abs_err','Absolute error'));
% %             m.plot(t, abs((y-yr)./y), pm.nextPlot('rel_err','Relative error'));
%             pm.done;
%             pm.savePlots(d,types,[],true);
% %             
%             %% DEIM reduction error plots
%             pm.FilePrefix = 'deim_rm';
%             [errs, relerrs, times, deim_orders] = testing.DEIM.getDEIMReducedModelErrors(r, mu, 1);
%             testing.DEIM.getDEIMReducedModelErrors_plots(r, errs, relerrs, times, deim_orders, pm);
%             pm.savePlots(d,types,[1 2],true);
% 
%             %% Reduction process plots
%             pm.FilePrefix = 'deim_approx';
%             h = pm.nextPlot('singvals','Singular values of SVD for DEIM basis computation');
%             semilogy(h, m.Approx.SingularValues);
%             pm.savePlots(d,types,[],true);

            %% Plot for different M,M' values
%             pm.FilePrefix = 'comp_m_mdash';
%             [o, eo] = meshgrid([1 2 3 4 5 7 10 12 20 25 30],...
%                 [1 2 3 4 5 7 10 15 20 25 30 40]);
%             errs = testing.DEIM.computeDEIMErrors(...
%                 m.Approx, m.Data.ApproxTrainData, o(:), eo(:));
%             testing.DEIM.plotDEIMErrs(errs, pm);
%             figure(3); view(54,30);
%             figure(6); view(135,58);
%             pm.done;
%             pm.savePlots(d,types,[1 3 6],true);

            %% Mean required error orders over training data
%             [meanreqorder, ~, ~, t] = testing.DEIM.getMinRequiredErrorOrders(...
%                 m, [1e-1 1e-2 1e-4 1e-6], 1:3:r.System.f.MaxOrder); %#ok
%             t.Format = 'tex';
%             t.Caption = sprintf('Minimum/mean required error orders over %d training snapshots',...
%                 size(m.Data.ApproxTrainData.xi,2));
%             t.saveToFile(fullfile(d,'table_minreqorders.tex'));
%             t.display;
%             
            ea = tools.EstimatorAnalyzer(r);
            ea.LineWidth = 2;
            ea.MarkerSize = 12;
            ea.NumMarkers = 4;
            
            %% Error estimator check for M,M' DEIM approx error est
            % Using true log norm
%             r.System.f.Order = 6;
%             r.ErrorEstimator.UseTrueLogLipConst = true;
%             ea.SaveTexTables = fullfile(d,'table_mdash.tex');
%             ea.Est = testing.DEIM.getDEIMEstimators_ErrOrders(r,[1 2 3 5 10]);
%             pm.FilePrefix = 'err_mdash';
% %             pm.MaxLegendRows = 7;
%             [~, ~, errs] = ea.start(mu,1,pm);
%             pm.createZoom(1,[.7 1 .9*min(errs(:,end)) 1.1*max(errs(:,end))]);
%             pm.done;
%             pm.savePlots(d,types,[1 4],true);
            
            %% Error estimator check for M,M' DEIM approx error est
            % Using approx JacDEIM & ST
            r.System.f.Order = 6;
            r.ErrorEstimator.UseTrueLogLipConst = false;
            r.ErrorEstimator.JacMatDEIMOrder = 10;
            r.ErrorEstimator.JacSimTransSize = 10;
            ea.SaveTexTables = fullfile(d,'table_mdash.tex');
            est = testing.DEIM.getDEIMEstimators_ErrOrders(r,[1 2 3 5 10]);
            % Change color of current reference estimate
            est(2).Color = [.9 .6 0]; %orange
            li = tools.LineSpecIterator;
            li.excludeColor([est(1).Color; est(2).Color; [0 0.5 0]]); % take out fixed colors
            for i=3:length(est)
                est(i).Color = li.nextColor;
            end
            % Add comparison plot
            est(end+1).Name = 'Prev. ref. est.';
            est(end).Estimator = r.ErrorEstimator.clone;
            est(end).Estimator.UseTrueDEIMErr = true;
            est(end).Estimator.UseTrueLogLipConst = true;
            est(end).MarkerStyle = 'p';
            est(end).LineStyle = '-';
            est(end).Color = [0 0.5 0];
            ea.Est = est;
            pm.FilePrefix = 'err_mdash_jacd_st';
%             pm.MaxLegendRows = 4;
            [~, ~, errs] = ea.start(mu,1,pm);
            pm.createZoom(1,[.7 1 .9*min(errs(:,end)) 1.1*max(errs(:,end))]);
            pm.done;
            pm.savePlots(d,types,[1 4],true);

            %% JacMDEIM & SimTrans error plots
%             r.System.f.Order = [6 10];
%             r.ErrorEstimator.UseTrueLogLipConst = false;
%             ea.SaveTexTables = fullfile(d,'table_jac_st.tex');
%             ea.Est = testing.DEIM.getDEIMEstimators_MDEIM_ST(r,[1 3 10],[1 3 10]);
%             ea.NumMarkers = 3;
%             pm.FilePrefix = 'err_jac_st';
% %             pm.MaxLegendRows = 6;
%             [~, ~, errs] = ea.start(mu,1,pm);
%             pm.createZoom(1,[.7 1 .9*min(errs(:,end)) 1.1*max(errs(:,end))]);
%             pm.done;
%             pm.savePlots(d,types,[1 4],true,[true false]);
        end
        
        function m = test_Burgers
            m = models.burgers.Burgers;
            
            %% Sampling - manual
            s = sampling.ManualSampler;
            s.Samples = logspace(log10(0.04),log10(0.08),150);
            m.Sampler = s;
            
            %% Approx
            a = approx.KernelApprox;
            a.Kernel = kernels.GaussKernel;
            a.ParamKernel = kernels.GaussKernel;
            
            al = approx.algorithms.VectorialKernelOMP;
            al.MaxGFactor = [1.5 0 1.5];
            al.MinGFactor = [.2 0 .6];
            al.gameps = 1e-4;
            al.MaxExpansionSize = 300;
            al.MaxAbsErrFactor = 1e-5;
            al.MaxRelErr = 1e-3;
            al.NumGammas = 40;
            a.Algorithm = al;
            m.Approx = a;
            
            m.offlineGenerations;
            save test_Burgers;
        end
        
        function m = test_Burgers_DEIM(dim, version)
            if nargin < 2
                version = 1;
                if nargin < 1
                    dim = 2000;
                end
            end
            m = models.burgers.Burgers(dim, version);
            
            if dim < 1000
                m.ModelData.TrajectoryData = data.MemoryTrajectoryData;
            else
                m.ModelData.TrajectoryData = data.FileTrajectoryData(m.ModelData);
            end
            
            %% Sampling - manual
            s = sampling.ManualSampler;
            s.Samples = logspace(log10(0.04),log10(0.08),100);
            m.Sampler = s;
            
            %% Approx
            a = approx.DEIM;
            a.MaxOrder = 80;
            m.Approx = a;
            
            offline_times = m.offlineGenerations;
            gitbranch = KerMor.getGitBranch;
            
            clear a s;
            d = fullfile(KerMor.App.DataStoreDirectory,'test_Burgers_DEIM');
            mkdir(d);
            oldd = pwd;
            cd(d);
            eval(sprintf('save test_Burgers_DEIM_d%d_v%d',dim,version));
            cd(oldd);
        end
        
        function m = test_Burgers_DEIM_B(dim)
            if nargin < 1
                dim = 100;
            end
            m = models.burgers.Burgers(dim, 2);
            %m.PlotAzEl = [-130 26];
            m.PlotAzEl = [-49 34];
            
            if dim > 500
                m.Data.TrajectoryData = [];
                m.Data.TrajectoryData = data.FileTrajectoryData(m.Data);
            end
            
            %% Sampling - log-grid
            m.System.Params(1).Range = [0.01, 0.06];
            m.System.Params(1).Desired = 100;
            s = sampling.GridSampler;
            s.Spacing = 'log';
            m.Sampler = s;
            
            %% Space reduction
            p = spacereduction.PODReducer;
            p.Mode = 'abs';
            p.Value = 44;
            m.SpaceReducer = p;
            
            %% Approx
            a = approx.DEIM;
            a.MaxOrder = 80;
            m.Approx = a;
            
            s = m.System;
            s.x0 = dscomponents.ConstInitialValue(zeros(dim,1));
            
            x = linspace(m.Omega(1),m.Omega(2),dim+2);
            x = x(2:end-1);
            pos1 = logical((x >= .1) .* (x <= .3));
            pos2 = logical((x >= .6) .* (x <= .7));
            %% Not that exciting set of inputs
%             s.Inputs{1} = @(t)2*sin(2*t*pi);
%             B = zeros(dim,1);
%             B(pos1) = 4*exp(-((x(pos1)-.2)/.03).^2);
%             B(pos2) = 1;
%             
            s.Inputs{1} = @(t)[sin(2*t*pi); (t>.2)*(t<.4)];
            B = zeros(dim,2);
            B(pos1,1) = 4*exp(-((x(pos1)-.2)/.03).^2);
            B(pos2,2) = 4;
            
            s.B = dscomponents.LinearInputConv(B);

            m.TrainingInputs = 1;
            
            t(1) = m.off1_createParamSamples;
            t(2) = m.off2_genTrainingData;
            t(3) = m.off3_computeReducedSpace;
            d = fullfile(KerMor.App.DataStoreDirectory,'test_Burgers_DEIM_B');
            
            % code for singular value export for higher dims
%             pm = tools.PlotManager; pm.FilePrefix = 'statespace_POD';
%             h = pm.nextPlot(sprintf('svals_d%d',dim),...
%                 sprintf('Singular values of state space POD, n=%d',dim));
%             semilogy(h,m.SpaceReducer.SingularValues);
%             pm.savePlots(d,{'fig','pdf','jpg'},[],true);
%             if dim > 100
%                 return;
%             end

            t(4) = m.off4_genApproximationTrainData;
            t(5) = m.off5_computeApproximation;
            t(6) = m.off6_prepareErrorEstimator;
            offline_times = t;
%             offline_times = m.offlineGenerations;
            gitcommit = KerMor.getGitBranch;
            
            clear a s;
            [~,~] = mkdir(d);
            oldd = pwd;
            cd(d);
            eval(sprintf('save test_Burgers_DEIM_B_d%d',dim));
            cd(oldd);
        end
    end
    
end