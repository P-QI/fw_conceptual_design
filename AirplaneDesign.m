% *************************************************************************
%          AirplaneDesign.m: Solar-powered UAV Conceptual Design
% *************************************************************************
% Descr.: Use this file to perform the conceptual design of your solar- 
%   powered UAV, i.e. analyse its performance (in the form of excess time,
%   charge margin, endurance and minimum battery state-of-charge) as a
%   function of its design variables (wing span b, aspect ratio AR, battery
%   mass m_bat). One can also design configurations considering different
%   atmospheric clearness (e.g. clouds) and turbulence (e.g. wind) values.
% Authors: P. Oettershagen, S. Leutenegger (2009-2015), based on A. Noth
% *************************************************************************

% Initialize
clear variables;
close all;
clc;
addpath(genpath('matlab_functions')) 

% -------------------------------------------------------------------------
% STEP 1: DESIGN SETUP
% -------------------------------------------------------------------------
% Set the three variables to choose as design variables here. Choices are the
% labels defined in the file VAR.m (i.e. VAR.WING_SPAN, VAR.BATTERY_MASS,
% VAR.ASPECT_RATIO, VAR.CLEARNESS and VAR.TURBULENCE, VAR.DAY_OF_YEAR, VAR.LATITUDE). 
%
% There is basically two design ways:
% 1. Specify wing span, battery mass and aspect ratio ranges to design your 
%    airplane first
% 2. Then (optionally) choose the optimal wing span and aspect ratio from the 
%    first step, and set 'VAR.BATTERY_MASS','VAR.CLEARNESS' and 'VAR.TURBULENCE'
%    to optimize the partially-fixed configuration in more detail over the 
%    remaining variables.
%
% Example:
% vars(1)= VAR.WING_SPAN;
% vars(1).values = 3:1:5; %Analyse over wing spans from 3 to 5m in 1m steps

%Plot1
vars(1) = VAR.WING_SPAN;
vars(1).values = 3.5:1.0:6.5;
vars(2) = VAR.BATTERY_MASS;
vars(2).values = 2.5:1.0:6.5;
vars(3) = VAR.ASPECT_RATIO;
vars(3).values = 18.5;

% Plot3
% vars(1) = VAR.CLEARNESS; %VAR.BATTERY_MASS;
% vars(1).values = 0.4:0.2:1;
% vars(2) = VAR.TURBULENCE; %VAR.WING_SPAN;
% vars(2).values = 0.0:0.2:0.6; %5.4:0.1:5.8;
% vars(3) = VAR.DAY_OF_YEAR;
% vars(3).values = [floor(3*30.5+21), floor(5*30.5+21)];

% Plot2
% vars(1) = VAR.DAY_OF_YEAR; %VAR.BATTERY_MASS;
% vars(1).values = [5*365/12+21 5*365/12+30 6*365/12+15];%floor(0*30.5):5:floor(11*30.5+29);
% vars(2) = VAR.LATITUDE; 
% vars(2).values = 47.6;%0:2.5:70;
% vars(3) = VAR.ASPECT_RATIO;
% vars(3).values = 18.5;

% Airplane general technological parameters first
initParameters;
params.structure.corr_fact = 1.21;    % Structural mass correction factor. Set to 
                                      % * 1.0 to use the original model without correction.
                                      % * 1.21 to correspond to AtlantikSolar initial structural mass calculation by D. Siebenmann

% This is the default configuration for our design variables! 
% (which is only used if we don't design over b, m_bat or AR)
plane.struct.b = 5.6;
plane.struct.AR = 18.5;
plane.bat.m = 2.9;

%This is the other plane-specific data. 
plane.avionics.power = 6.0;
plane.avionics.mass = 1.20;
plane.payload.power = 0;
plane.payload.mass = 0.0;
plane.prop.P_prop_max = 180.0;

% Set environment
environment.dayofyear = 5*30.5+21;
environment.lat = 47.6;                     % 1: Barcelona 2:Tuggen/CH
environment.lon = 8.53;
environment.h_0 = 416+120;                  % with 120m AGL flight altitude for enough safety
environment.h_max = 700;                   % Barcelona: 4000ft
environment.T_ground = 25+273.15;
environment.turbulence = 0;
environment.turbulence_day = 0.0;           % Relative increase of power consumption during the day, e.g. due to thermals
environment.clearness = 1.0;
environment.albedo = 0.12;
environment.add_solar_timeshift = -3600;    % [s], due to Daylight Saving Time (DST), actually used for solar income calculations
environment.plot_solar_timeshift = -1.533;  % [h], just used for plotting results (to plot them in solar time), does not affect anything else

%Evaluation settings
settings.DEBUG = 0;                         % Force DEBUG mode
settings.dt = 100;                          % Discretization time interval [s]
settings.climbAllowed = 0;
settings.SimType = 0;                       % 0 = Start on t_eq, 1 = start on specified Initial Conditions
settings.SimTimeDays = 2;                   % Simulation Time in days (e.g. 1 = std. 24h simulation)
settings.InitCond.SoC = 0.46;               % State-of-charge [-]
settings.InitCond.t = 4.0*3600 + 32*60;     % [s]launch time
settings.evaluation.findalt = 0;            % if 1, it finds the maximum altitude for eternal flight
%settings.optGRcruise       =  0;           % 1 to allow cruise at optimal glide ratio & speed when max altitude reached 
settings.useAOI = 0;                        % 1 to enable the use of angle-of-incidence dependent solar module efficiency
settings.useDirDiffRad = 0;                 % 1 to enable the use of separate diffuse and direct radiation solar module efficiencies

% -------------------------------------------------------------------------
% STEP 2: Calculate performance results
% -------------------------------------------------------------------------

% Number of configurations calculated
N = numel(vars(1).values) * numel(vars(2).values) * numel(vars(3).values);
disp(['Number of configurations to be calculated: ' num2str(N)]);
h=waitbar(0,'Progress');

% Calculate performance results
str='';
ctr = 0;
for i = 1:numel(vars(3).values)
    for k = 1:numel(vars(2).values)
        for j = 1:numel(vars(1).values)
            
            ctr = ctr+1;
            varval(3)=vars(3).values(i);
            varval(2)=vars(2).values(k);
            varval(1)=vars(1).values(j);
            
            %Assign variables dynamically
            idx = find(vars == VAR.WING_SPAN,1,'first');
            if ~isempty(idx) ; plane.struct.b = varval(idx); end
            idx = find(vars == VAR.BATTERY_MASS,1,'first');
            if ~isempty(idx) ; plane.bat.m = varval(idx); end
            idx = find(vars == VAR.ASPECT_RATIO,1,'first');
            if ~isempty(idx) ; plane.struct.AR = varval(idx); end
            idx = find(vars == VAR.CLEARNESS,1,'first');
            if ~isempty(idx) ; environment.clearness = varval(idx); end
            idx = find(vars == VAR.TURBULENCE,1,'first');
            if ~isempty(idx) ; environment.turbulence = varval(idx); end
            idx = find(vars == VAR.DAY_OF_YEAR,1,'first');
            if ~isempty(idx) ; environment.dayofyear = varval(idx); end
            idx = find(vars == VAR.LATITUDE,1,'first');
            if ~isempty(idx) ; environment.lat = varval(idx); end
            
            [PerfResults(i,k,j),DesignResults(i,k,j),flightdata(i,k,j)] = ...
               evaluateSolution(plane,environment,params,settings);
           
            if(abs(environment.plot_solar_timeshift) > 0.01)
                PerfResults(i,k,j).t_eq2 = PerfResults(i,k,j).t_eq2 + environment.plot_solar_timeshift * 3600;
                PerfResults(i,k,j).t_fullcharge = PerfResults(i,k,j).t_fullcharge + environment.plot_solar_timeshift * 3600;
                PerfResults(i,k,j).t_sunrise = PerfResults(i,k,j).t_sunrise + environment.plot_solar_timeshift * 3600;
                PerfResults(i,k,j).t_max = PerfResults(i,k,j).t_max + environment.plot_solar_timeshift * 3600;
                PerfResults(i,k,j).t_sunset = PerfResults(i,k,j).t_sunset + environment.plot_solar_timeshift * 3600;
                PerfResults(i,k,j).t_eq = PerfResults(i,k,j).t_eq + environment.plot_solar_timeshift * 3600;
            end 
           
           str = [str sprintf('#%d| Set: b:%g m_bat:%g AR:%g   DoY=%g,Lat=%g,CLR=%g,Turb=%g   Res:Soc_min=%.2f%%,T_exc=%.2fh,T_cm=%.2fh,T_end=%.2fh   CharTimes:t_sr=%.2fh t_eq1=%.2fh t_fc=%.2fh t_fc90=NA t_eq2=%.2fh t_ss=%.2fh m=%.2f P=%.2f\n',ctr,...
                flightdata(i,k,j).b,flightdata(i,k,j).m_bat,flightdata(i,k,j).AR,...
                environment.dayofyear,environment.lat,environment.clearness,environment.turbulence,...
                PerfResults(i,k,j).min_SoC*100,PerfResults(i,k,j).t_excess,PerfResults(i,k,j).t_chargemargin,PerfResults(i,k,j).t_endurance,...
                PerfResults(i,k,j).t_sunrise/3600,PerfResults(i,k,j).t_eq/3600,PerfResults(i,k,j).t_fullcharge/3600, PerfResults(i,k,j).t_eq2/3600, PerfResults(i,k,j).t_sunset/3600,...
                DesignResults(i,k,j).m_no_bat+DesignResults(i,k,j).m_bat,PerfResults(i,k,j).P_elec_level_tot_nom)];
            
            completedRatio = ((i-1)*numel(vars(2).values)*numel(vars(1).values) + (k-1)*numel(vars(1).values) + j)/N;
            waitbar(completedRatio,h,[num2str(completedRatio*100.0,'Progress: %.0f\n') '%']);
        end
    end
end
close(h)

display('*** Performance solutions ***');
display(str);

% -------------------------------------------------------------------------
% STEP 3: Plotting
% -------------------------------------------------------------------------
% Note: Plotting scripts are located in the matlab_functions/PlotScripts
% folder. Please modify and call these scripts if you want to modify the 
% plots

Plot_AirplaneDesign_Standard(PerfResults, DesignResults, environment, plane, params, flightdata, vars);
%Plot_AirplaneDesign_ASFinalPaper_PlotOrderChanged(PerfResults, DesignResults, environment, plane, params, flightdata, vars);

if(numel(vars(1).values)*numel(vars(2).values)*numel(vars(3).values)==1)
    Plot_BasicSimulationTimePlot(flightdata,environment,params, plane)
end