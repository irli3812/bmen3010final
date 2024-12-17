% BMEN3010 Final Project
% Iris Li
% BMEN3010
% Final Project Dec 2024
% Help from ChatGPT
close all; clc;

%% Variables
syms nri nrs vs
ncs = 0;
keR = 0.03;
kdegR = 0.0022;
krec = 0.08;
fR = 0.2;
fL = 0.5;
k_as = 7.2e7;
k_dis = 0.3;
CL = 0;
nli = 0;
nrt = 0.5e5;
kdegL = 0.01;
keC = 0.3;

NC = 1e9;
NA = 6.023e23;

%% A
dnrs = -k_as*CL*nrs + k_dis*ncs - keR*nrs + krec*(1-fR)*nri + vs == 0;
dnri = keR*nrs + keC*ncs - (kdegR*fR + krec*(1-fR))*nri == 0;
addition = nrs + ncs + nri == nrt;

sol = solve([dnrs, dnri, addition], [vs, nri, nrs]);

% Simplify solutions:
VS = simplify(sol.vs);
NRI = simplify(sol.nri);
NRS = simplify(sol.nrs);

params = struct('k1', k_as, 'k_1', k_dis, 'keR', keR, 'keC', keC, ...
    'krec', krec, 'kdegR', kdegR, 'fR', fR, 'CL', CL, 'nrt', nrt);

vs_eval = double(subs(VS, params));
V_S = double(vs_eval);
nri_eval = double(subs(NRI, params));
nrs_eval = double(subs(NRS, params));

disp('Solved SS form for N_RI, N_RS, VS: ');
fprintf('V_S = %.4f\n', vs_eval);
fprintf('N_RI = %.4f\n', nri_eval);
fprintf('N_RS = %.4f\n', nrs_eval);


%% B
% y(1) is NRS; y(2) is NRI
system = @(t,y) [
    -keR*y(1) + krec*(1-fR)*y(2) + V_S;  % 2nd eqn listed
    keR*y(1) - (kdegR*fR + krec*(1-fR))*y(2) % 4th eqn listed
   ];

y0 = [nri_eval; nrs_eval]; % initial conds
timespan = [0,200];

[t,y] = ode45(system, timespan, y0);

% extract solns:
nrs_soln = y(:,1);
nri_soln = y(:,2);

figure();
plot(t,nrs_soln, 'LineWidth', 1.5);
hold on
plot(t,nri_soln, 'LineWidth', 1.5);
title('(B) Receptor levels inside and outside cell');
ylim([0, max(max(nrs_soln), max(nri_soln))*1.5]);
xlim([50,200]);
xlabel('time (mins)');
ylabel('receptors/cell');
legend("Surface receptors (N_R_S)", "Inner Receptors (N_R_I)", 'Location', 'best');
grid on;
hold off


%% C
timespanCD = [0,250];
nrs_initial = double(nrs_eval); %double(nrs_eval);
ncs_initial = 0; %double(ncs);
nri_initial = double(nri_eval); %double(nri_eval);
nli_initial = 0; %double(nli);

CLarray = [1e-9,2e-9,5e-9,1e-8,5e-8,1e-7];

figure();

for i = 1:length(CLarray)
    CL_initial = CLarray(i);
    initialconds = [CL_initial, nrs_initial, ncs_initial, nri_initial, nli_initial];
    
    [t,y] = ode45(@(t,y) syseqns(t,y,k_as,k_dis,keR,keC,krec,kdegR,kdegL,fR,fL,NC,NA,V_S), timespanCD, initialconds);

    subplot(3,2,i);
    plot(t,y(:,5), 'LineWidth', 1); % N_LI
    hold on
    plot(t,y(:,3), 'LineWidth', 1);
    plot(t,y(:,2), 'LineWidth', 1);
    plot(t,y(:,4), 'LineWidth', 1);
    title(['C_L = ', num2str(CL_initial, '%.1e'), ' M']);
    xlabel('time (mins)');
    ylabel('Concentration'); % units
    legend('N_L_I', 'N_C_S', 'N_R_S', 'N_R_I');
    grid on;
end

sgtitle('(C) N_L_I and N_C_S vs. Time for Different C_L levels');

%% System of equations for C
% eqns stands for equations
function eqns = syseqns(t,y,k_as,k_dis,keR,keC,krec,kdegR,kdegL,fR,fL,NC,NA,V_S)
    C_L = y(1);
    N_RS = y(2);
    N_CS = y(3);
    N_RI = y(4);
    N_LI = y(5);
    eqns = zeros(5,1);
    eqns(1) = (NC/NA)*1e3*(-k_as*y(1)*y(2)+k_dis*y(3)+krec*(1-fL)*y(5));
    eqns(2) = -k_as*y(1)*y(2) + k_dis*y(3) - keR*y(2) + krec*(1-fR)*y(4) + V_S;
    eqns(3) = k_as*y(1)*y(2) -(k_dis+keC)*y(3);
    eqns(4) = keR*y(2) + keC*y(3) - (kdegR*fR + krec*(1-fR))*y(4);
    eqns(5) = keC*y(3) - (kdegL*fL + krec*(1-fL))*y(5);
end


%% D
% Pre-allocations:
ratios = zeros(length(CLarray), 250);
time = cell(length(CLarray), 1);

for i=1:length(CLarray)
    initialCL = CLarray(i);
    initials = [CL_initial, nrs_initial, ncs_initial, nri_initial, nli_initial];

    [t,y] = ode45(@(t,y) syseqns(t,y,k_as,k_dis,keR,keC,krec,kdegR,kdegL,fR,fL,NC,NA,V_S), timespanCD, initials);

    % CL/CL0 ratio (R)
    CLtot = y(:,1);
    R = CLtot/initialCL;
    ratios(i, 1:length(t)) = R;
    time{i} = t;
end

figure();
hold on
for i = 1:length(CLarray)
    plot(time{i}, ratios(i, 1:length(time{i})), 'LineWidth', 1);
end
grid on;
xlabel('time (mins)');
ylabel('C_L / C_L_0');
legend(arrayfun(@(c) sprintf('C_L = %.1e', c), CLarray, 'UniformOutput', false), 'Location', 'best');
title('(D) Ligand depletion (C_L / C_L_0) vs. time for different C_L levels');
hold off

