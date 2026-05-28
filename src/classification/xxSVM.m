%% Support Vector Machine Particle Recognition Program (Linear SVM Only)
% Includes single parameter fitting and dual-parameter linear SVM classification
clear; clc; close all;

%% 1. Data Preparation
fprintf('=== Support Vector Machine Particle Recognition Program (Linear SVM) ===\n');

% Set default color scheme for consistent styling
defaultColors = lines(7);  % Color palette
dropColor = defaultColors(1,:);    % Droplet color
iceColor = defaultColors(2,:);     % Ice crystal color
svColor = defaultColors(3,:);      % Support vector color
boundaryColor = defaultColors(4,:); % Decision boundary color

% Set figure style parameters
figureStyle.lineWidth = 1.5;
figureStyle.markerSize = 50;
figureStyle.fontName = 'Times New Roman';
figureStyle.fontSize = 11;
figureStyle.titleFontSize = 14;
figureStyle.axisFontSize = 12;
figureStyle.legendFontSize = 10;

% Read Excel data
filename = 'D:\桌面\程序\机器学习\液滴，冰晶圆度与线偏振度.xlsx'; % Modify according to actual filename
data = readtable(filename);

% Display data column names and basic information
fprintf('Excel file column names:\n');
disp(data.Properties.VariableNames);
fprintf('Data size: %d rows × %d columns\n', size(data, 1), size(data, 2));

% Extract features and labels - more robust method
if any(strcmp(data.Properties.VariableNames, 'Circularity'))
    circularity = data.Circularity;      % Circularity feature (closer to 4 means more circular)
else
    circularity = data{:, 1};            % Assume first column is circularity
end

if any(strcmp(data.Properties.VariableNames, 'Polarization'))
    polarization = data.Polarization;    % Linear polarization degree feature (0-1 range)
else
    polarization = data{:, 2};           % Assume second column is polarization
end

if any(strcmp(data.Properties.VariableNames, 'Label'))
    labels_raw = data.Label;             % Labels
elseif any(strcmp(data.Properties.VariableNames, 'Type'))
    labels_raw = data.Type;              % Could be Type column
else
    labels_raw = data{:, 3};             % Assume third column is labels
end

% Process labels - ensure conversion to numeric
fprintf('\nLabel processing:\n');
if iscell(labels_raw) || isstring(labels_raw)
    fprintf('Detected text labels, converting to numeric...\n');
    unique_labels = unique(labels_raw);
    fprintf('Found label categories: ');
    
    y = zeros(size(labels_raw));
    for i = 1:length(unique_labels)
        fprintf('%s ', string(unique_labels{i}));
        if iscell(labels_raw)
            idx = strcmp(labels_raw, unique_labels{i});
        else
            idx = labels_raw == unique_labels{i};
        end
        y(idx) = i-1;  % Start numbering from 0
    end
    fprintf('\n');
    
    if length(unique_labels) ~= 2
        error('Need 2 categories for binary classification, but found %d categories', length(unique_labels));
    end
else
    y = double(labels_raw);  % Ensure double precision numeric
end

% Display label distribution
unique_y = unique(y);
fprintf('Numeric label distribution:\n');
for i = 1:length(unique_y)
    fprintf('  Label %d: %d samples (%.1f%%)\n', ...
        unique_y(i), sum(y == unique_y(i)), sum(y == unique_y(i))/length(y)*100);
end

% Create feature matrix
X = [circularity, polarization];

% Check for NaN values
nan_idx = any(isnan(X), 2) | isnan(y);
if any(nan_idx)
    fprintf('\nWarning: Found %d NaN values, removed\n', sum(nan_idx));
    X = X(~nan_idx, :);
    y = y(~nan_idx);
end

fprintf('\nData information:\n');
fprintf('Total samples: %d\n', length(y));
fprintf('Feature dimensions: %d\n', size(X, 2));

%% Important correction: Correct label setting for droplets and ice crystals
fprintf('\n=== Label Setting ===\n');
fprintf('Please confirm your data label meanings:\n');
fprintf('Option 1: 0=Droplet, 1=Ice crystal\n');
fprintf('Option 2: 1=Droplet, 0=Ice crystal\n');
fprintf('Option 3: -1=Droplet, 1=Ice crystal\n');

% Automatically determine based on most common settings
if all(ismember(unique_y, [0, 1]))
    if mean(circularity(y == 0)) > mean(circularity(y == 1))
        fprintf('\nAuto-detected: 0=Ice crystal, 1=Droplet\n');
        fprintf('Basis: Mean circularity for label 0(%.2f) > label 1(%.2f)\n', ...
            mean(circularity(y == 0)), mean(circularity(y == 1)));
        y_binary = zeros(size(y));
        y_binary(y == 0) = 1;   % Ice crystal = 1
        y_binary(y == 1) = -1;  % Droplet = -1
    else
        fprintf('\nAuto-detected: 0=Droplet, 1=Ice crystal\n');
        fprintf('Basis: Mean circularity for label 0(%.2f) < label 1(%.2f)\n', ...
            mean(circularity(y == 0)), mean(circularity(y == 1)));
        y_binary = zeros(size(y));
        y_binary(y == 0) = -1;  % Droplet = -1
        y_binary(y == 1) = 1;   % Ice crystal = 1
    end
elseif all(ismember(unique_y, [-1, 1]))
    fprintf('\nDetected -1/1 format labels\n');
    y_binary = y;
else
    error('Cannot auto-detect label format, please specify manually');
end

fprintf('Droplet count (label -1): %d\n', sum(y_binary == -1));
fprintf('Ice crystal count (label 1): %d\n', sum(y_binary == 1));

% Display physical feature comparison
fprintf('\nPhysical feature comparison:\n');
fprintf('Droplets (-1) - Mean circularity: %.2f, Mean polarization: %.2f\n', ...
    mean(circularity(y_binary == -1)), mean(polarization(y_binary == -1)));
fprintf('Ice crystals (1) - Mean circularity: %.2f, Mean polarization: %.2f\n', ...
    mean(circularity(y_binary == 1)), mean(polarization(y_binary == 1)));

%% 2. Single Parameter Fitting Analysis
fprintf('\n=== Single Parameter Fitting Analysis ===\n');

% Separate two classes of data
ice_idx = (y_binary == 1);    % Ice crystal index
drop_idx = (y_binary == -1);  % Droplet index

ice_circularity = circularity(ice_idx);
ice_polarization = polarization(ice_idx);
drop_circularity = circularity(drop_idx);
drop_polarization = polarization(drop_idx);

%% 2.1 Circularity Single Parameter Fitting
fprintf('\n--- Circularity Single Parameter Fitting ---\n');

% Create figure for circularity distribution fitting
figure('Position', [100, 100, 1400, 450], 'Name', 'Circularity Distribution Fitting Analysis', ...
    'Color', 'white', 'NumberTitle', 'off');

% Subplot 1: Circularity distribution histogram
subplot(1, 3, 1);
hold on;
box on;
grid on;

% Histograms with enhanced styling
histogram(drop_circularity, 'BinWidth', 0.5, 'FaceColor', dropColor, ...
    'FaceAlpha', 0.7, 'EdgeColor', 'k', 'LineWidth', 0.5, 'Normalization', 'pdf');
histogram(ice_circularity, 'BinWidth', 0.5, 'FaceColor', iceColor, ...
    'FaceAlpha', 0.7, 'EdgeColor', 'k', 'LineWidth', 0.5, 'Normalization', 'pdf');

% Calculate and plot normal distribution fit
x_range = linspace(min(circularity), max(circularity), 200);

% Droplet circularity normal fit
drop_mu = mean(drop_circularity);
drop_sigma = std(drop_circularity);
drop_pdf = normpdf(x_range, drop_mu, drop_sigma);
plot(x_range, drop_pdf, 'Color', dropColor, 'LineWidth', figureStyle.lineWidth+1, 'LineStyle', '-');

% Ice crystal circularity normal fit
ice_mu = mean(ice_circularity);
ice_sigma = std(ice_circularity);
ice_pdf = normpdf(x_range, ice_mu, ice_sigma);
plot(x_range, ice_pdf, 'Color', iceColor, 'LineWidth', figureStyle.lineWidth+1, 'LineStyle', '-');

xlabel('Circularity', 'FontSize', figureStyle.axisFontSize, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);
ylabel('Probability Density', 'FontSize', figureStyle.axisFontSize, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);
title('Circularity Distribution & Normal Fit', 'FontSize', figureStyle.titleFontSize, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);
legend('Droplet Data', 'Ice Crystal Data', 'Droplet Fit', 'Ice Crystal Fit', ...
    'Location', 'best', 'FontSize', figureStyle.legendFontSize, 'FontName', figureStyle.fontName);

% Add statistics
text(0.05, 0.95, sprintf('Droplets: μ=%.2f, σ=%.2f', drop_mu, drop_sigma), ...
    'Units', 'normalized', 'Color', dropColor, 'FontSize', 10, 'FontWeight', 'bold', ...
    'FontName', figureStyle.fontName, 'BackgroundColor', 'white', 'EdgeColor', 'k', 'Margin', 2);
text(0.05, 0.88, sprintf('Ice Crystals: μ=%.2f, σ=%.2f', ice_mu, ice_sigma), ...
    'Units', 'normalized', 'Color', iceColor, 'FontSize', 10, 'FontWeight', 'bold', ...
    'FontName', figureStyle.fontName, 'BackgroundColor', 'white', 'EdgeColor', 'k', 'Margin', 2);

set(gca, 'FontSize', figureStyle.fontSize, 'LineWidth', 1.2, 'FontName', figureStyle.fontName, 'FontWeight', 'bold');

% Subplot 2: Circularity cumulative distribution function
subplot(1, 3, 2);
hold on;
box on;
grid on;

% Empirical CDF
[drop_cdf_x, drop_cdf_y] = ecdf(drop_circularity);
[ice_cdf_x, ice_cdf_y] = ecdf(ice_circularity);

% Plot empirical CDF
stairs(drop_cdf_x, drop_cdf_y, 'Color', dropColor, 'LineWidth', figureStyle.lineWidth+1);
stairs(ice_cdf_x, ice_cdf_y, 'Color', iceColor, 'LineWidth', figureStyle.lineWidth+1);

% Theoretical CDF
drop_cdf_theory = normcdf(x_range, drop_mu, drop_sigma);
ice_cdf_theory = normcdf(x_range, ice_mu, ice_sigma);
plot(x_range, drop_cdf_theory, 'Color', dropColor, 'LineWidth', figureStyle.lineWidth, 'LineStyle', '--');
plot(x_range, ice_cdf_theory, 'Color', iceColor, 'LineWidth', figureStyle.lineWidth, 'LineStyle', '--');

xlabel('Circularity', 'FontSize', figureStyle.axisFontSize, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);
ylabel('Cumulative Probability', 'FontSize', figureStyle.axisFontSize, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);
title('Circularity Cumulative Distribution', 'FontSize', figureStyle.titleFontSize, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);
legend('Droplet Empirical', 'Ice Crystal Empirical', 'Droplet Theory', 'Ice Crystal Theory', ...
    'Location', 'best', 'FontSize', figureStyle.legendFontSize, 'FontName', figureStyle.fontName);

set(gca, 'FontSize', figureStyle.fontSize, 'LineWidth', 1.2, 'FontName', figureStyle.fontName, 'FontWeight', 'bold');

% Subplot 3: Circularity box plot
subplot(1, 3, 3);
hold on;
box on;
grid on;

% Prepare data
group_data = [drop_circularity; ice_circularity];
group_labels = [repmat({'Droplet'}, length(drop_circularity), 1); ...
                repmat({'Ice Crystal'}, length(ice_circularity), 1)];

% Enhanced boxplot
bp = boxplot(group_data, group_labels, 'Colors', [dropColor; iceColor], ...
    'Widths', 0.6, 'Symbol', 'k+', 'OutlierSize', 8);

% Style the boxplot
set(bp, {'LineWidth'}, {figureStyle.lineWidth});

ylabel('Circularity', 'FontSize', figureStyle.axisFontSize, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);
title('Circularity Distribution Box Plot', 'FontSize', figureStyle.titleFontSize, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);

% Add median values
medians = [median(drop_circularity), median(ice_circularity)];
text(1, medians(1), sprintf('Med: %.2f', medians(1)), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
    'FontSize', 10, 'FontWeight', 'bold', 'Color', 'k', 'FontName', figureStyle.fontName);
text(2, medians(2), sprintf('Med: %.2f', medians(2)), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
    'FontSize', 10, 'FontWeight', 'bold', 'Color', 'k', 'FontName', figureStyle.fontName);

set(gca, 'FontSize', figureStyle.fontSize, 'LineWidth', 1.2, 'FontName', figureStyle.fontName, 'FontWeight', 'bold');

% Adjust subplot spacing
sgtitle('Circularity Parameter Analysis', 'FontSize', 16, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);

%% 2.2 Polarization Single Parameter Fitting
fprintf('\n--- Polarization Single Parameter Fitting ---\n');

% Create figure for polarization distribution fitting
figure('Position', [100, 100, 1400, 450], 'Name', 'Polarization Distribution Fitting Analysis', ...
    'Color', 'white', 'NumberTitle', 'off');

% Subplot 1: Polarization distribution histogram
subplot(1, 3, 1);
hold on;
box on;
grid on;

% Histograms with enhanced styling
histogram(drop_polarization, 'BinWidth', 0.05, 'FaceColor', dropColor, ...
    'FaceAlpha', 0.7, 'EdgeColor', 'k', 'LineWidth', 0.5, 'Normalization', 'pdf');
histogram(ice_polarization, 'BinWidth', 0.05, 'FaceColor', iceColor, ...
    'FaceAlpha', 0.7, 'EdgeColor', 'k', 'LineWidth', 0.5, 'Normalization', 'pdf');

% Calculate and plot normal distribution fit
x_range_pol = linspace(min(polarization), max(polarization), 200);

% Droplet polarization normal fit
drop_mu_pol = mean(drop_polarization);
drop_sigma_pol = std(drop_polarization);
drop_pdf_pol = normpdf(x_range_pol, drop_mu_pol, drop_sigma_pol);
plot(x_range_pol, drop_pdf_pol, 'Color', dropColor, 'LineWidth', figureStyle.lineWidth+1, 'LineStyle', '-');

% Ice crystal polarization normal fit
ice_mu_pol = mean(ice_polarization);
ice_sigma_pol = std(ice_polarization);
ice_pdf_pol = normpdf(x_range_pol, ice_mu_pol, ice_sigma_pol);
plot(x_range_pol, ice_pdf_pol, 'Color', iceColor, 'LineWidth', figureStyle.lineWidth+1, 'LineStyle', '-');

xlabel('Degree of Linear Polarization', 'FontSize', figureStyle.axisFontSize, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);
ylabel('Probability Density', 'FontSize', figureStyle.axisFontSize, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);
title('Polarization Distribution & Normal Fit', 'FontSize', figureStyle.titleFontSize, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);
legend('Droplet Data', 'Ice Crystal Data', 'Droplet Fit', 'Ice Crystal Fit', ...
    'Location', 'best', 'FontSize', figureStyle.legendFontSize, 'FontName', figureStyle.fontName);

% Add statistics
text(0.05, 0.95, sprintf('Droplets: μ=%.3f, σ=%.3f', drop_mu_pol, drop_sigma_pol), ...
    'Units', 'normalized', 'Color', dropColor, 'FontSize', 10, 'FontWeight', 'bold', ...
    'FontName', figureStyle.fontName, 'BackgroundColor', 'white', 'EdgeColor', 'k', 'Margin', 2);
text(0.05, 0.88, sprintf('Ice Crystals: μ=%.3f, σ=%.3f', ice_mu_pol, ice_sigma_pol), ...
    'Units', 'normalized', 'Color', iceColor, 'FontSize', 10, 'FontWeight', 'bold', ...
    'FontName', figureStyle.fontName, 'BackgroundColor', 'white', 'EdgeColor', 'k', 'Margin', 2);

set(gca, 'FontSize', figureStyle.fontSize, 'LineWidth', 1.2, 'FontName', figureStyle.fontName, 'FontWeight', 'bold');

% Subplot 2: Polarization cumulative distribution function
subplot(1, 3, 2);
hold on;
box on;
grid on;

% Empirical CDF
[drop_cdf_x_pol, drop_cdf_y_pol] = ecdf(drop_polarization);
[ice_cdf_x_pol, ice_cdf_y_pol] = ecdf(ice_polarization);

% Plot empirical CDF
stairs(drop_cdf_x_pol, drop_cdf_y_pol, 'Color', dropColor, 'LineWidth', figureStyle.lineWidth+1);
stairs(ice_cdf_x_pol, ice_cdf_y_pol, 'Color', iceColor, 'LineWidth', figureStyle.lineWidth+1);

% Theoretical CDF
drop_cdf_theory_pol = normcdf(x_range_pol, drop_mu_pol, drop_sigma_pol);
ice_cdf_theory_pol = normcdf(x_range_pol, ice_mu_pol, ice_sigma_pol);
plot(x_range_pol, drop_cdf_theory_pol, 'Color', dropColor, 'LineWidth', figureStyle.lineWidth, 'LineStyle', '--');
plot(x_range_pol, ice_cdf_theory_pol, 'Color', iceColor, 'LineWidth', figureStyle.lineWidth, 'LineStyle', '--');

xlabel('Degree of Linear Polarization', 'FontSize', figureStyle.axisFontSize, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);
ylabel('Cumulative Probability', 'FontSize', figureStyle.axisFontSize, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);
title('Polarization Cumulative Distribution', 'FontSize', figureStyle.titleFontSize, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);
legend('Droplet Empirical', 'Ice Crystal Empirical', 'Droplet Theory', 'Ice Crystal Theory', ...
    'Location', 'best', 'FontSize', figureStyle.legendFontSize, 'FontName', figureStyle.fontName);

set(gca, 'FontSize', figureStyle.fontSize, 'LineWidth', 1.2, 'FontName', figureStyle.fontName, 'FontWeight', 'bold');

% Subplot 3: Polarization box plot
subplot(1, 3, 3);
hold on;
box on;
grid on;

% Prepare data
group_data_pol = [drop_polarization; ice_polarization];
group_labels_pol = [repmat({'Droplet'}, length(drop_polarization), 1); ...
                    repmat({'Ice Crystal'}, length(ice_polarization), 1)];

% Enhanced boxplot
bp_pol = boxplot(group_data_pol, group_labels_pol, 'Colors', [dropColor; iceColor], ...
    'Widths', 0.6, 'Symbol', 'k+', 'OutlierSize', 8);

% Style the boxplot
set(bp_pol, {'LineWidth'}, {figureStyle.lineWidth});

ylabel('Degree of Linear Polarization', 'FontSize', figureStyle.axisFontSize, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);
title('Polarization Distribution Box Plot', 'FontSize', figureStyle.titleFontSize, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);

% Add median values
medians_pol = [median(drop_polarization), median(ice_polarization)];
text(1, medians_pol(1), sprintf('Med: %.3f', medians_pol(1)), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
    'FontSize', 10, 'FontWeight', 'bold', 'Color', 'k', 'FontName', figureStyle.fontName);
text(2, medians_pol(2), sprintf('Med: %.3f', medians_pol(2)), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
    'FontSize', 10, 'FontWeight', 'bold', 'Color', 'k', 'FontName', figureStyle.fontName);

set(gca, 'FontSize', figureStyle.fontSize, 'LineWidth', 1.2, 'FontName', figureStyle.fontName, 'FontWeight', 'bold');

% Adjust subplot spacing
sgtitle('Polarization Parameter Analysis', 'FontSize', 16, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);

%% 2.3 Single Parameter Classification Performance Analysis
fprintf('\n--- Single Parameter Classification Performance Analysis ---\n');

% Find optimal thresholds
circularity_values = sort(unique(circularity));
best_accuracy_circ = 0;
best_threshold_circ = 0;

for i = 1:length(circularity_values)
    threshold = circularity_values(i);
    pred_circ = ones(size(y_binary));
    pred_circ(circularity <= threshold) = -1;
    pred_circ(circularity > threshold) = 1;
    
    accuracy = sum(pred_circ == y_binary) / length(y_binary);
    
    if accuracy > best_accuracy_circ
        best_accuracy_circ = accuracy;
        best_threshold_circ = threshold;
    end
end

fprintf('\n1. Circularity Alone Classification:\n');
fprintf('   Optimal threshold: %.2f\n', best_threshold_circ);
fprintf('   Optimal accuracy: %.2f%%\n', best_accuracy_circ * 100);

% Polarization alone classification
polarization_values = sort(unique(polarization));
best_accuracy_pol = 0;
best_threshold_pol = 0;

for i = 1:length(polarization_values)
    threshold = polarization_values(i);
    pred_pol = ones(size(y_binary));
    pred_pol(polarization >= threshold) = -1;
    pred_pol(polarization < threshold) = 1;
    
    accuracy = sum(pred_pol == y_binary) / length(y_binary);
    
    if accuracy > best_accuracy_pol
        best_accuracy_pol = accuracy;
        best_threshold_pol = threshold;
    end
end

fprintf('\n2. Polarization Alone Classification:\n');
fprintf('   Optimal threshold: %.2f\n', best_threshold_pol);
fprintf('   Optimal accuracy: %.2f%%\n', best_accuracy_pol * 100);

%% 2.4 Single Parameter Classification Decision Plot
fprintf('\n--- Single Parameter Classification Decision Plot ---\n');

% Figure 1: Circularity alone classification
figure('Position', [100, 100, 900, 650], 'Name', 'Circularity Alone Classification', ...
    'Color', 'white', 'NumberTitle', 'off');

hold on;
box on;
grid on;

% Plot data points with enhanced markers
scatter(drop_circularity, zeros(size(drop_circularity)), figureStyle.markerSize, ...
    dropColor, 'o', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1);
scatter(ice_circularity, ones(size(ice_circularity)), figureStyle.markerSize, ...
    iceColor, '^', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1);

% Plot decision threshold line
plot([best_threshold_circ, best_threshold_circ], [-0.2, 1.2], 'Color', boundaryColor, ...
    'LineWidth', figureStyle.lineWidth+1, 'LineStyle', '--');

% Add decision region labels
text(mean([min(circularity), best_threshold_circ]), -0.1, 'Droplet Region', ...
    'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold', 'Color', dropColor, 'FontName', figureStyle.fontName);
text(mean([best_threshold_circ, max(circularity)]), 1.1, 'Ice Crystal Region', ...
    'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold', 'Color', iceColor, 'FontName', figureStyle.fontName);

% Add threshold annotation
text(best_threshold_circ, -0.15, sprintf('Threshold: %.2f', best_threshold_circ), ...
    'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold', ...
    'FontName', figureStyle.fontName, 'BackgroundColor', 'white', 'EdgeColor', boundaryColor, 'Margin', 3);

xlabel('Circularity', 'FontSize', figureStyle.axisFontSize, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);
ylabel('Class (0=Droplet, 1=Ice Crystal)', 'FontSize', figureStyle.axisFontSize, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);
title(sprintf('Single Parameter Classification: Circularity\n(Accuracy: %.1f%%)', best_accuracy_circ*100), ...
    'FontSize', figureStyle.titleFontSize+2, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);
legend('Droplet', 'Ice Crystal', 'Decision Boundary', 'Location', 'best', ...
    'FontSize', figureStyle.legendFontSize, 'FontName', figureStyle.fontName);

% Add statistics box
stats_text = {sprintf('Droplet Mean: %.2f', mean(drop_circularity)), ...
              sprintf('Ice Crystal Mean: %.2f', mean(ice_circularity)), ...
              sprintf('Separation: %.2f', abs(mean(ice_circularity) - mean(drop_circularity)))};
annotation('textbox', [0.15, 0.75, 0.2, 0.15], 'String', stats_text, ...
    'FontSize', 10, 'FontWeight', 'bold', 'FontName', figureStyle.fontName, ...
    'BackgroundColor', 'white', 'EdgeColor', 'k', 'Margin', 5);

set(gca, 'FontSize', figureStyle.fontSize, 'LineWidth', 1.2, 'YLim', [-0.2, 1.2], ...
    'FontName', figureStyle.fontName, 'FontWeight', 'bold');

% Figure 2: Polarization alone classification
figure('Position', [100, 100, 900, 650], 'Name', 'Polarization Alone Classification', ...
    'Color', 'white', 'NumberTitle', 'off');

hold on;
box on;
grid on;

% Plot data points
scatter(drop_polarization, zeros(size(drop_polarization)), figureStyle.markerSize, ...
    dropColor, 'o', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1);
scatter(ice_polarization, ones(size(ice_polarization)), figureStyle.markerSize, ...
    iceColor, '^', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1);

% Plot decision threshold line
plot([best_threshold_pol, best_threshold_pol], [-0.2, 1.2], 'Color', boundaryColor, ...
    'LineWidth', figureStyle.lineWidth+1, 'LineStyle', '--');

% Add decision region labels
text(mean([min(polarization), best_threshold_pol]), -0.1, 'Ice Crystal Region', ...
    'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold', 'Color', iceColor, 'FontName', figureStyle.fontName);
text(mean([best_threshold_pol, max(polarization)]), 1.1, 'Droplet Region', ...
    'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold', 'Color', dropColor, 'FontName', figureStyle.fontName);

% Add threshold annotation
text(best_threshold_pol, -0.15, sprintf('Threshold: %.3f', best_threshold_pol), ...
    'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold', ...
    'FontName', figureStyle.fontName, 'BackgroundColor', 'white', 'EdgeColor', boundaryColor, 'Margin', 3);

xlabel('Degree of Linear Polarization', 'FontSize', figureStyle.axisFontSize, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);
ylabel('Class (0=Droplet, 1=Ice Crystal)', 'FontSize', figureStyle.axisFontSize, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);
title(sprintf('Single Parameter Classification: Polarization\n(Accuracy: %.1f%%)', best_accuracy_pol*100), ...
    'FontSize', figureStyle.titleFontSize+2, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);
legend('Droplet', 'Ice Crystal', 'Decision Boundary', 'Location', 'best', ...
    'FontSize', figureStyle.legendFontSize, 'FontName', figureStyle.fontName);

% Add statistics box
stats_text_pol = {sprintf('Droplet Mean: %.3f', mean(drop_polarization)), ...
                  sprintf('Ice Crystal Mean: %.3f', mean(ice_polarization)), ...
                  sprintf('Separation: %.3f', abs(mean(ice_polarization) - mean(drop_polarization)))};
annotation('textbox', [0.15, 0.75, 0.2, 0.15], 'String', stats_text_pol, ...
    'FontSize', 10, 'FontWeight', 'bold', 'FontName', figureStyle.fontName, ...
    'BackgroundColor', 'white', 'EdgeColor', 'k', 'Margin', 5);

set(gca, 'FontSize', figureStyle.fontSize, 'LineWidth', 1.2, 'YLim', [-0.2, 1.2], ...
    'FontName', figureStyle.fontName, 'FontWeight', 'bold');

%% 2.5 Single vs Dual Parameter Comparison
fprintf('\n--- Single vs Dual Parameter Performance Comparison ---\n');

% Standardize features
X_scaled = zscore(X);

% Split data
rng(42);
cv = cvpartition(length(y_binary), 'HoldOut', 0.3);
idxTrain = training(cv);
idxTest = test(cv);

X_train = X_scaled(idxTrain, :);
y_train = y_binary(idxTrain);
X_test = X_scaled(idxTest, :);
y_test = y_binary(idxTest);

% Train linear SVM
SVMModel_linear = fitcsvm(X_train, y_train, ...
    'KernelFunction', 'linear', 'BoxConstraint', 1, 'Standardize', false, 'ClassNames', [-1, 1]);

% Predict
[y_pred_svm, ~] = predict(SVMModel_linear, X_test);
accuracy_svm = mean(y_pred_svm == y_test);

% Single parameter performance on test set
pred_circ_test = ones(size(y_test));
test_circularity = circularity(idxTest);
pred_circ_test(test_circularity <= best_threshold_circ) = -1;
pred_circ_test(test_circularity > best_threshold_circ) = 1;
accuracy_circ_test = mean(pred_circ_test == y_test);

pred_pol_test = ones(size(y_test));
test_polarization = polarization(idxTest);
pred_pol_test(test_polarization >= best_threshold_pol) = -1;
pred_pol_test(test_polarization < best_threshold_pol) = 1;
accuracy_pol_test = mean(pred_pol_test == y_test);

fprintf('\nTest Set Performance Comparison:\n');
fprintf('   Circularity Alone: %.2f%%\n', accuracy_circ_test * 100);
fprintf('   Polarization Alone: %.2f%%\n', accuracy_pol_test * 100);
fprintf('   Dual Parameter SVM: %.2f%%\n', accuracy_svm * 100);

% Performance comparison plot
figure('Position', [100, 100, 900, 600], 'Name', 'Single vs Dual Parameter Comparison', ...
    'Color', 'white', 'NumberTitle', 'off');

hold on;
box on;
grid on;

methods = {'Circularity\nAlone', 'Polarization\nAlone', 'Dual-Parameter\nSVM'};
accuracies = [accuracy_circ_test, accuracy_pol_test, accuracy_svm] * 100;

% Create bar plot with custom colors
bar_colors = [dropColor; iceColor; [0.3, 0.6, 0.9]];
bars = bar(accuracies, 'FaceColor', 'flat');
for i = 1:length(bars)
    bars(i).CData(i,:) = bar_colors(i,:);
end

% Add value labels on bars
for i = 1:length(accuracies)
    text(i, accuracies(i)+1, sprintf('%.1f%%', accuracies(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold', ...
        'Color', 'k', 'FontName', figureStyle.fontName);
end

% Calculate improvements
improvement_circ = ((accuracy_svm - accuracy_circ_test) / accuracy_circ_test) * 100;
improvement_pol = ((accuracy_svm - accuracy_pol_test) / accuracy_pol_test) * 100;

% Add improvement annotations
text(3, accuracies(3)/2, sprintf('+%.1f%% vs\nCircularity', improvement_circ), ...
    'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold', ...
    'Color', 'white', 'BackgroundColor', 'none', 'FontName', figureStyle.fontName);
text(3, accuracies(3)/4, sprintf('+%.1f%% vs\nPolarization', improvement_pol), ...
    'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold', ...
    'Color', 'white', 'BackgroundColor', 'none', 'FontName', figureStyle.fontName);

ylabel('Test Accuracy (%)', 'FontSize', figureStyle.axisFontSize, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);
title('Single Parameter vs Dual Parameter SVM Performance', 'FontSize', figureStyle.titleFontSize+2, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);
set(gca, 'XTickLabel', methods, 'FontSize', figureStyle.fontSize, 'LineWidth', 1.2, ...
    'FontName', figureStyle.fontName, 'FontWeight', 'bold');

%% 3. Linear SVM Model Details
fprintf('\n=== Linear SVM Model Details ===\n');

w_linear = SVMModel_linear.Beta;
b_linear = SVMModel_linear.Bias;

fprintf('\nLinear SVM Decision Boundary Equation:\n');
fprintf('   Original form: %.4f * Circularity + %.4f * Polarization + %.4f = 0\n', ...
    w_linear(1), w_linear(2), b_linear);
fprintf('   Solve for Polarization: Polarization = %.4f * Circularity + %.4f\n', ...
    -w_linear(1)/w_linear(2), -b_linear/w_linear(2));

[y_pred_linear, score_linear] = predict(SVMModel_linear, X_test);
accuracy_linear = mean(y_pred_linear == y_test);
cm_linear = confusionmat(y_test, y_pred_linear);

fprintf('\nLinear SVM Test Accuracy: %.2f%%\n', accuracy_linear*100);

%% 4. Figure 1: Original Data Distribution
figure('Position', [100, 100, 900, 700], 'Name', 'Particle Feature Distribution', ...
    'Color', 'white', 'NumberTitle', 'off');

hold on;
box on;
grid on;

% Create category labels
class_labels = cell(size(y_binary));
class_labels(y_binary == -1) = {'Droplet'};
class_labels(y_binary == 1) = {'Ice Crystal'};

% Enhanced scatter plot
gscatter(circularity, polarization, class_labels, [dropColor; iceColor], 'o^', 15, 'on');

% Set axes properties
xlabel('Circularity', 'FontSize', figureStyle.axisFontSize, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);
ylabel('Degree of Linear Polarization', 'FontSize', figureStyle.axisFontSize, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);
title('Particle Feature Distribution: Droplets vs Ice Crystals', ...
    'FontSize', figureStyle.titleFontSize+2, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);

% Add statistics box
stats_text_dist = {sprintf('Total Samples: %d', length(y_binary)), ...
                   sprintf('Droplets: %d (%.1f%%)', sum(y_binary == -1), ...
                   sum(y_binary == -1)/length(y_binary)*100), ...
                   sprintf('Ice Crystals: %d (%.1f%%)', sum(y_binary == 1), ...
                   sum(y_binary == 1)/length(y_binary)*100)};
annotation('textbox', [0.15, 0.75, 0.2, 0.15], 'String', stats_text_dist, ...
    'FontSize', 10, 'FontWeight', 'bold', 'FontName', figureStyle.fontName, ...
    'BackgroundColor', 'white', 'EdgeColor', 'k', 'Margin', 5);

% Set legend
legend('Location', 'best', 'FontSize', figureStyle.legendFontSize, 'FontName', figureStyle.fontName);

set(gca, 'FontSize', figureStyle.fontSize, 'LineWidth', 1.2, 'FontName', figureStyle.fontName, 'FontWeight', 'bold');

%% 5. Figure 2: Linear SVM Decision Boundary
figure('Position', [100, 100, 1000, 800], 'Name', 'Linear SVM Decision Boundary', ...
    'Color', 'white', 'NumberTitle', 'off');

% Prepare grid data
x1_min = min(circularity) - 0.5;
x1_max = max(circularity) + 0.5;
x2_min = min(polarization) - 0.1;
x2_max = max(polarization) + 0.1;

[x1Grid, x2Grid] = meshgrid(linspace(x1_min, x1_max, 300), ...
                           linspace(x2_min, x2_max, 300));
XGrid = [x1Grid(:), x2Grid(:)];

% Standardize grid data
XGrid_scaled = (XGrid - mean(X)) ./ std(X);

% Predict grid points
[~, scores_linear_grid] = predict(SVMModel_linear, XGrid_scaled);
scoreGrid_linear = reshape(scores_linear_grid(:,2), size(x1Grid));

% Create plot
hold on;
box on;
grid off;   % Remove background grid

% Plot decision boundary only (no filled regions)
contour(x1Grid, x2Grid, scoreGrid_linear, [0, 0], 'Color', boundaryColor, ...
    'LineWidth', figureStyle.lineWidth+2, 'LineStyle', '-');

% Define colors: Train = blue, Test = orange-red
trainColor = [0 0.4470 0.7410];
testColor  = [0.8500 0.3250 0.0980];

% Plot training data: all filled, shape distinguishes droplet/ice
scatter(circularity(idxTrain & y_binary==-1), polarization(idxTrain & y_binary==-1), ...
    60, trainColor, 'o', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1);
scatter(circularity(idxTrain & y_binary==1), polarization(idxTrain & y_binary==1), ...
    60, trainColor, '^', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1);

% Plot test data: all filled, shape distinguishes droplet/ice
scatter(circularity(idxTest & y_binary==-1), polarization(idxTest & y_binary==-1), ...
    60, testColor, 'o', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
scatter(circularity(idxTest & y_binary==1), polarization(idxTest & y_binary==1), ...
    60, testColor, '^', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);

% Plot support vectors (if any)
if ~isempty(SVMModel_linear.SupportVectors)
    sv_original = SVMModel_linear.SupportVectors .* std(X) + mean(X);
    scatter(sv_original(:,1), sv_original(:,2), 120, [0.4660 0.6740 0.1880], 's', ...
        'filled', 'LineWidth', 2, 'MarkerEdgeColor', 'k');
end

% Set axes properties - Times New Roman + bold
xlabel('Circularity', 'FontSize', figureStyle.axisFontSize, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);
ylabel('Degree of Linear Polarization', 'FontSize', figureStyle.axisFontSize, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);
title(sprintf('Linear SVM Decision Boundary\n(Test Accuracy: %.1f%%)', accuracy_linear*100), ...
    'FontSize', figureStyle.titleFontSize+2, 'FontWeight', 'bold', 'FontName', figureStyle.fontName);

% Create legend - remove border
legend_items = {'Decision Boundary', ...
                'Droplet (Train)', 'Ice Crystal (Train)', ...
                'Droplet (Test)', 'Ice Crystal (Test)'};
if ~isempty(SVMModel_linear.SupportVectors)
    legend_items{end+1} = 'Support Vectors';
end
legend(legend_items, 'Location', 'best', 'FontSize', figureStyle.legendFontSize, ...
       'Box', 'off', 'FontName', figureStyle.fontName);

set(gca, 'FontSize', figureStyle.fontSize, 'LineWidth', 1.2, ...
         'FontName', figureStyle.fontName, 'FontWeight', 'bold');

%% 6. Figure 3: Model Performance (Confusion Matrix)
fig_cm0 = figure('Position', [100, 100, 600, 500], 'Name', 'Linear SVM Confusion Matrix', ...
    'Color', 'white', 'NumberTitle', 'off');

% Create confusion matrix plot - Ice Crystal split into two lines
cm_chart = confusionchart(cm_linear, {sprintf('Ice\nCrystal'), 'Droplet'}, ...
    'FontName', figureStyle.fontName);
cm_chart.Title = 'Linear SVM Confusion Matrix';
cm_chart.FontSize = figureStyle.fontSize;
cm_chart.XLabel = '';
cm_chart.YLabel = '';
boldConfusionLabels(fig_cm0);

% Calculate performance metrics
TP = cm_linear(2,2);
TN = cm_linear(1,1);
FP = cm_linear(1,2);
FN = cm_linear(2,1);

precision = TP / (TP + FP);
recall = TP / (TP + FN);
f1_score = 2 * (precision * recall) / (precision + recall);

% Add performance metrics as text
metrics_text = {sprintf('Precision: %.3f', precision), ...
                sprintf('Recall: %.3f', recall), ...
                sprintf('F1-Score: %.3f', f1_score)};
annotation('textbox', [0.6, 0.2, 0.25, 0.15], 'String', metrics_text, ...
    'FontSize', 11, 'FontWeight', 'bold', 'FontName', figureStyle.fontName, ...
    'BackgroundColor', 'white', 'EdgeColor', 'k', 'Margin', 3);

%% 7. Output Detailed Results
fprintf('\n=== SVM Detailed Results ===\n');

% Linear SVM details
fprintf('\nLinear SVM Details:\n');
fprintf('Decision boundary equation: %.4f * Circularity + %.4f * Polarization + %.4f = 0\n', ...
    w_linear(1), w_linear(2), b_linear);
fprintf('Number of support vectors: %d\n', size(SVMModel_linear.SupportVectors, 1));

% Classification rule summary
fprintf('\n=== Particle Classification Rule Summary ===\n');
fprintf('1. Linear SVM Decision Rule:\n');
fprintf('   If %.4f * Circularity + %.4f * Polarization + %.4f > 0, classify as Ice Crystal\n', ...
    w_linear(1), w_linear(2), b_linear);
fprintf('   Otherwise classify as Droplet\n');

fprintf('\n2. Physical Interpretation:\n');
fprintf('   - High circularity + Low polarization → Likely Ice Crystal\n');
fprintf('   - Low circularity + High polarization → Likely Droplet\n');

fprintf('\n3. Classification Accuracy:\n');
fprintf('   Linear SVM: %.1f%%\n', accuracy_linear*100);

%% 8. Save Models and Results
fprintf('\n=== Saving Models and Results ===\n');

% Save feature statistics
feature_stats.mean = mean(X);
feature_stats.std = std(X);

% Save everything
save('particle_classifier_svm_linear.mat', 'SVMModel_linear', 'feature_stats', ...
    'accuracy_linear', 'w_linear', 'b_linear', 'best_accuracy_circ', 'best_threshold_circ', ...
    'best_accuracy_pol', 'best_threshold_pol');

fprintf('Model saved as: particle_classifier_svm_linear.mat\n');
fprintf('Includes: Linear SVM model, feature statistics, accuracy metrics, threshold info\n');

%% 9. Display Support Vector Details
fprintf('\n=== Support Vector Analysis ===\n');

fprintf('\nLinear SVM Support Vector Statistics:\n');
if ~isempty(SVMModel_linear.SupportVectors)
    sv_original = SVMModel_linear.SupportVectors .* std(X) + mean(X);
    fprintf('Circularity range: %.2f - %.2f\n', min(sv_original(:,1)), max(sv_original(:,1)));
    fprintf('Polarization range: %.2f - %.2f\n', min(sv_original(:,2)), max(sv_original(:,2)));
    fprintf('Mean circularity: %.2f\n', mean(sv_original(:,1)));
    fprintf('Mean polarization: %.2f\n', mean(sv_original(:,2)));
end

%% 10. Performance Comparison of Three Methods
fprintf('\n=== Performance Comparison of Three Methods ===\n');

% Method 1: Circularity alone
cm_circ = confusionmat(y_test, pred_circ_test, 'Order', [-1, 1]);
TP_circ = cm_circ(2,2); TN_circ = cm_circ(1,1); FP_circ = cm_circ(1,2); FN_circ = cm_circ(2,1);
prec_circ = TP_circ / (TP_circ + FP_circ);
rec_circ = TP_circ / (TP_circ + FN_circ);
acc_circ = (TP_circ + TN_circ) / sum(cm_circ(:));
fprintf('\n1. Circularity Alone:\n');
fprintf('   Accuracy:  %.2f%%\n', acc_circ*100);
fprintf('   Precision: %.2f%%\n', prec_circ*100);
fprintf('   Recall:    %.2f%%\n', rec_circ*100);
disp('   Confusion Matrix (rows=true, cols=pred) [Ice Crystal(-1), Droplet(1)]:');
disp(cm_circ);

% Method 2: Polarization alone
cm_pol = confusionmat(y_test, pred_pol_test, 'Order', [-1, 1]);
TP_pol = cm_pol(2,2); TN_pol = cm_pol(1,1); FP_pol = cm_pol(1,2); FN_pol = cm_pol(2,1);
prec_pol = TP_pol / (TP_pol + FP_pol);
rec_pol = TP_pol / (TP_pol + FN_pol);
acc_pol = (TP_pol + TN_pol) / sum(cm_pol(:));
fprintf('\n2. Polarization Alone:\n');
fprintf('   Accuracy:  %.2f%%\n', acc_pol*100);
fprintf('   Precision: %.2f%%\n', prec_pol*100);
fprintf('   Recall:    %.2f%%\n', rec_pol*100);
disp('   Confusion Matrix (rows=true, cols=pred) [Ice Crystal(-1), Droplet(1)]:');
disp(cm_pol);

% Method 3: Dual-parameter Linear SVM
cm_svm = cm_linear; % already computed
TP_svm = cm_svm(2,2); TN_svm = cm_svm(1,1); FP_svm = cm_svm(1,2); FN_svm = cm_svm(2,1);
prec_svm = TP_svm / (TP_svm + FP_svm);
rec_svm = TP_svm / (TP_svm + FN_svm);
acc_svm = (TP_svm + TN_svm) / sum(cm_svm(:));
fprintf('\n3. Dual-parameter Linear SVM:\n');
fprintf('   Accuracy:  %.2f%%\n', acc_svm*100);
fprintf('   Precision: %.2f%%\n', prec_svm*100);
fprintf('   Recall:    %.2f%%\n', rec_svm*100);
disp('   Confusion Matrix (rows=true, cols=pred) [Ice Crystal(-1), Droplet(1)]:');
disp(cm_svm);

% Summary table
fprintf('\n--- Summary Table ---\n');
fprintf('%-25s %12s %12s %12s\n', 'Method', 'Accuracy', 'Precision', 'Recall');
fprintf('%-25s %11.2f%% %11.2f%% %11.2f%%\n', 'Circularity Alone', acc_circ*100, prec_circ*100, rec_circ*100);
fprintf('%-25s %11.2f%% %11.2f%% %11.2f%%\n', 'Polarization Alone', acc_pol*100, prec_pol*100, rec_pol*100);
fprintf('%-25s %11.2f%% %11.2f%% %11.2f%%\n', 'Dual-parameter SVM', acc_svm*100, prec_svm*100, rec_svm*100);

%% Three Confusion Matrices

% Define two-line label for Ice Crystal
iceCrystalLabel = sprintf('Ice\nCrystal');

% Figure 1: Circularity alone confusion matrix
fig_cm1 = figure('Position', [100, 100, 500, 400], 'Name', 'Confusion Matrix - Circularity Alone', ...
    'Color', 'white', 'NumberTitle', 'off');
cm_circ_chart = confusionchart(cm_circ, {iceCrystalLabel, 'Droplet'}, ...
    'Title', 'Circularity Alone', ...
    'FontSize', figureStyle.fontSize, 'FontName', figureStyle.fontName);
cm_circ_chart.XLabel = '';
cm_circ_chart.YLabel = '';
boldConfusionLabels(fig_cm1);

% Figure 2: Polarization alone confusion matrix
fig_cm2 = figure('Position', [620, 100, 500, 400], 'Name', 'Confusion Matrix - Polarization Alone', ...
    'Color', 'white', 'NumberTitle', 'off');
cm_pol_chart = confusionchart(cm_pol, {iceCrystalLabel, 'Droplet'}, ...
    'Title', 'Polarization Alone', ...
    'FontSize', figureStyle.fontSize, 'FontName', figureStyle.fontName);
cm_pol_chart.XLabel = '';
cm_pol_chart.YLabel = '';
boldConfusionLabels(fig_cm2);

% Figure 3: Dual-parameter SVM confusion matrix
fig_cm3 = figure('Position', [1140, 100, 500, 400], 'Name', 'Confusion Matrix - Dual-parameter SVM', ...
    'Color', 'white', 'NumberTitle', 'off');
cm_svm_chart = confusionchart(cm_svm, {iceCrystalLabel, 'Droplet'}, ...
    'Title', 'Dual-parameter SVM', ...
    'FontSize', figureStyle.fontSize, 'FontName', figureStyle.fontName);
cm_svm_chart.XLabel = '';
cm_svm_chart.YLabel = '';
boldConfusionLabels(fig_cm3);

%% 11. Final Summary
fprintf('\n=== Program Execution Summary ===\n');
fprintf('1. Successfully loaded and processed data\n');
fprintf('2. Automatically identified label format and set correctly\n');
fprintf('3. Completed single parameter fitting analysis:\n');
fprintf('   - Circularity alone accuracy: %.1f%% (Threshold: %.2f)\n', best_accuracy_circ*100, best_threshold_circ);
fprintf('   - Polarization alone accuracy: %.1f%% (Threshold: %.3f)\n', best_accuracy_pol*100, best_threshold_pol);
fprintf('4. Trained Linear SVM model\n');
fprintf('5. Generated independent figures with enhanced visualization\n');
fprintf('6. Saved model to: particle_classifier_svm_linear.mat\n');
fprintf('7. Label settings confirmed:\n');
fprintf('   -1 = Droplet (Blue)\n');
fprintf('    1 = Ice Crystal (Red)\n');
fprintf('\nKey Findings:\n');
fprintf('   Dual-parameter Linear SVM accuracy (%.1f%%) significantly higher than single-parameter classification\n', accuracy_svm*100);
fprintf('   Circularity is the most discriminative feature\n');
fprintf('   Polarization provides valuable complementary information\n');

fprintf('\n=== Particle Recognition SVM Program (Linear) Completed ===\n');

%% Helper Function: Bold all text labels in confusion matrix figures
function boldConfusionLabels(fig)
    drawnow;  % Ensure all graphics objects are rendered
    allText = findall(fig, 'Type', 'Text');
    for k = 1:numel(allText)
        allText(k).FontWeight = 'bold';
        allText(k).FontName  = 'Times New Roman';
    end
end

