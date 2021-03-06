% @author: Maziar Raissi

function main()
%% Pre-processing
clc; close all;
rng('default')

addpath ./Utilities

set(0,'defaulttextinterpreter','latex')

%% Setup
N_L = 12;
N_H = 3;
D = 1;
lb = 0.0*ones(1,D);
ub = 1.0*ones(1,D);
noise_L = 0.25;
noise_H = 0.00;

%% Generate Data
function f=f_H(x)
    f = 2.*pi.*cos(2.*pi.*x)+pi.^(-1).*sin(pi.*x).^2;   
end
X_H = bsxfun(@plus,lb,bsxfun(@times,   lhsdesign(N_H,D)    ,(ub-lb)));
y_H = f_H(X_H);
y_H = y_H + noise_H*std(y_H)*randn(N_H,1);

function f=f_L(x)
    f = 0.8*f_H(x) - 5*prod(x,2) - 6;
end
X_L = bsxfun(@plus,lb,bsxfun(@times,   lhsdesign(N_L,D)    ,(ub-lb)));
y_L = f_L(X_L);
y_L = y_L + noise_L*std(y_L)*randn(N_L,1);

N_star = 200;
X_star = linspace(lb(1), ub(1), N_star)';
f_H_star = f_H(X_star);
f_L_star = f_L(X_star);

%% Model Definition
model = Multifidelity_GP(X_L, y_L, X_H, y_H);

%% Model Training
model = model.train();

%% Make Predictions
[mean_f_H_star, var_f_H_star] = model.predict_H(X_star);

fprintf(1,'Relative L2 error f_H: %e\n', (norm(mean_f_H_star-f_H_star,2)/norm(f_H_star,2)));

%% Plot results
color = [55,126,184]/255;

fig = figure(1);
set(fig,'units','normalized','outerposition',[0 0 1 1])

clear h;
clear leg;
hold
h(1) = plot(X_star, f_H_star,'k','LineWidth',2);
h(2) = plot(X_H, y_H,'kx','MarkerSize',14, 'LineWidth',2);
h(3) = plot(X_star,mean_f_H_star,'b--','LineWidth',3);
[l,h(4)] = boundedline(X_star, mean_f_H_star, 2.0*sqrt(var_f_H_star), ':', 'alpha','cmap', color);
outlinebounds(l,h(4));
h(5) = plot(X_star, f_L_star,'k:','LineWidth',2);
h(6) = plot(X_L, y_L,'k+','MarkerSize',14, 'LineWidth',2);


leg{1} = '$f_H(x)$';
leg{2} = sprintf('%d high-fidelity training data', N_H);
leg{3} = '$\overline{f}_H(x)$'; leg{4} = 'Two standard deviations';
leg{5} = '$f_L(x)$';
leg{6} = sprintf('%d low-fidelity training data', N_L);

hl = legend(h,leg,'Location','northwestoutside');
legend boxoff
set(hl,'Interpreter','latex')
xlabel('$x$')
ylabel('$f_L(x), f_H(x)$')
title('A');

axis square
ylim(ylim + [-diff(ylim)/10 0]);
xlim(xlim + [-diff(xlim)/10 0]);
set(gca,'FontSize',16);
set(gcf, 'Color', 'w');


axes('Position',[0.05 0.35 .3 .3])
box on
hold
h(1) = plot(f_L_star, f_H_star,'b','LineWidth',3);
xlabel('$f_{L}(x)$');
ylabel('$f_{H}(x)$');
title('B -- Cross-correlation');
axis square
set(gca,'FontSize',16);
set(gca,'Xtick',[]);
set(gca,'Ytick',[]);
set(gcf, 'Color', 'w');

%% Post-processing
rmpath ./Utilities
end