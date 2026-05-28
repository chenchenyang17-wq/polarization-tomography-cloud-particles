close all;
clear all;
clc; 

%% ========================= 第一步：读取图像与预处理 =========================
pt = 'F:\冰晶·16.00；数浓度\再现结果\图30\粒子2（29.24）\';
ext = '*.bmp';
dis = dir(fullfile(pt, ext));

% 按日期排序图像（确保0°/45°/90°/135°顺序正确）
[~, index] = sort({dis.date});
dis = dis(index);
nms = {dis.name};

% 读取4个角度的偏振图像（转换为double格式）
image1 = double(imread([pt, nms{1}])); % 0°偏振图像
image2 = double(imread([pt, nms{2}])); % 45°偏振图像
image3 = double(imread([pt, nms{3}])); % 90°偏振图像
image4 = double(imread([pt, nms{4}])); % 135°偏振图像

% 对0°图像归一化（用于生成粒子/背景二值化掩码）
image11 = (image1 - min(min(image1))) ./ (max(max(image1)) - min(min(image1)));
threshod = 0.2; % 阈值（用于区分粒子与背景）


%% ========================= 第二步：生成粒子/背景二值化掩码 =========================
% 1. 粒子区域掩码：保留归一化后≥阈值的区域（原逻辑保留）
erzhiimg_particle = image11 >= threshod;
% 2. 背景区域掩码：反向阈值（保留<阈值的区域），用于提取背景
erzhiimg_bg = image11 < threshod;

% 可选：查看粒子/背景的二值化效果（便于调试阈值）
% figure('Name', '粒子-背景掩码对比');
% subplot(1,2,1); imshow(erzhiimg_particle); title('粒子区域掩码（≥0.2）');
% subplot(1,2,2); imshow(erzhiimg_bg); title('背景区域掩码（<0.2）');


%% ========================= 第三步：计算Stokes参数、DOLP、AOP（补全背景AOP） =========================
epsilon = 1e-10; % 用于避免除零错误

% ---------------------- 3.1 粒子区域计算（原逻辑保留，补全AOP变量注释） ----------------------
% 用粒子掩码提取粒子区域的图像数据
img1_particle = erzhiimg_particle .* image1; % 0°粒子区域
img2_particle = erzhiimg_particle .* image2; % 45°粒子区域
img3_particle = erzhiimg_particle .* image3; % 90°粒子区域
img4_particle = erzhiimg_particle .* image4; % 135°粒子区域

% 粒子区域Stokes参数
% S0_particle = (img3_particle + img1_particle + img2_particle + img4_particle)/2; % 总光强

S0_particle = img3_particle + img1_particle; % 总光强
S1_particle = img3_particle - img1_particle; % 水平-垂直偏振分量差
S2_particle = img2_particle - img4_particle; % 45°-135°偏振分量差

% 粒子区域偏振度（DOLP）
DOLP_particle = sqrt(S1_particle.^2 + S2_particle.^2) ./ (S0_particle + epsilon);

% 粒子区域偏振角（AOP）及归一化（原注释解除，确保变量定义）
AOP_particle = 0.5 * atan2(S2_particle, S1_particle + epsilon);
AOPNormalized_particle = (AOP_particle + pi/2) / pi; % 归一到[0,1]


% ---------------------- 3.2 背景区域计算（补全AOP，保留原DOLP逻辑） ----------------------
% 用背景掩码提取背景区域的图像数据
img1_bg = erzhiimg_bg .* image1; % 0°背景区域
img2_bg = erzhiimg_bg .* image2; % 45°背景区域
img3_bg = erzhiimg_bg .* image3; % 90°背景区域
img4_bg = erzhiimg_bg .* image4; % 135°背景区域

% 背景区域Stokes参数（与粒子区域公式一致，仅掩码不同）
S0_bg = img3_bg + img1_bg; % 总光强
S1_bg = img3_bg - img1_bg; % 水平-垂直偏振分量差
S2_bg = img2_bg - img4_bg; % 45°-135°偏振分量差

% 背景区域偏振度（DOLP）（原逻辑保留，补充epsilon避免除零）
DOLP_bg = sqrt(S1_bg.^2 + S2_bg.^2) ./ (S0_bg + epsilon);

% 新增：背景区域偏振角（AOP）及归一化（公式与粒子区域一致）
AOP_bg = 0.5 * atan2(S2_bg, S1_bg + epsilon);
AOPNormalized_bg = (AOP_bg + pi/2) / pi; % 归一到[0,1]


%% ========================= 第四步：手动框选计算平均值（新增背景AOP计算） =========================
% ---------------------- 4.1 粒子区域：偏振度（原逻辑保留） ----------------------
fprintf('=== 请在「粒子区域偏振度图」中框选粒子区域 ===\n');
[mean_dolp_particle, valid_count_particle] = calc_mean_dolp(DOLP_particle, '粒子区域偏振度', false);

% ---------------------- 4.2 背景区域：偏振度（原逻辑保留） ----------------------
fprintf('\n=== 请在「背景区域偏振度图」中框选背景区域 ===\n');
[mean_dolp_bg, valid_count_bg] = calc_mean_dolp(DOLP_bg, '背景区域偏振度', true);

% ---------------------- 4.3 粒子区域：偏振角（原逻辑保留） ----------------------
fprintf('\n=== 请在「粒子区域偏振角图」中框选粒子区域 ===\n');
[mean_AOPNorm_particle, mean_AOP_deg_particle, valid_count_AOP_particle] = ...
    calc_mean_angle(AOPNormalized_particle, '粒子区域AOPNormalized', true); % 粒子需处理0.5

% ---------------------- 4.4 新增：背景区域：偏振角（不处理0.5） ----------------------
fprintf('\n=== 请在「背景区域偏振角图」中框选背景区域 ===\n');
[mean_AOPNorm_bg, mean_AOP_deg_bg, valid_count_AOP_bg] = ...
    calc_mean_angle(AOPNormalized_bg, '背景区域AOPNormalized', false); % 背景不处理0.5


%% ========================= 第五步：输出最终结果（补充背景AOP结果） =========================
fprintf('\n=========================================\n');
fprintf('最终偏振分析结果（粒子 vs 背景）\n');
fprintf('=========================================\n');

% 1. 偏振度（DOLP）结果
fprintf('【偏振度（DOLP）对比】\n');
fprintf('  粒子区域平均DOLP：%.4f  |  有效像素数：%d\n', mean_dolp_particle, valid_count_particle);
fprintf('  背景区域平均DOLP：%.4f  |  有效像素数：%d\n', mean_dolp_bg, valid_count_bg);
fprintf('-----------------------------------------\n');

% 2. 偏振角（AOP）结果（原粒子结果保留，新增背景结果）
fprintf('【偏振角（AOP）对比】\n');
fprintf('  粒子区域：\n');
fprintf('    归一化平均AOP：%.4f  |  实际角度：%.1f°  |  有效像素数：%d\n', ...
    mean_AOPNorm_particle, mean_AOP_deg_particle, valid_count_AOP_particle);
fprintf('  背景区域：\n');
fprintf('    归一化平均AOP：%.4f  |  实际角度：%.1f°  |  有效像素数：%d\n', ...
    mean_AOPNorm_bg, mean_AOP_deg_bg, valid_count_AOP_bg);
fprintf('=========================================\n');
fprintf('注：1. 粒子区域AOP的0.5值已排除；2. 背景区域AOP保留0.5值；3. 所有NaN值已排除\n');


%% ========================= 通用函数定义（修改calc_mean_angle适配背景规则）=========================
% 函数1：计算平均偏振度（原逻辑保留，无修改）
function [mean_dolp, valid_count] = calc_mean_dolp(DOLP_matrix, fig_title, is_background)
    % 显示DOLP图像
    figure('Name', fig_title);
    imshow(DOLP_matrix);
    title([fig_title, '（拖动鼠标框选区域，完成后按Enter）']);
    colormap(jet); % 使用jet配色
    colorbar;
    
    % 手动框选区域
    h = imrect; % 交互式矩形选择工具
    position = wait(h); % 等待用户确认选择（按Enter）
    
    % 提取框选坐标并取整
    x1 = round(position(1));
    y1 = round(position(2));
    width = round(position(3));
    height = round(position(4));
    x2 = x1 + width - 1;
    y2 = y1 + height - 1;
    
    % 确保坐标在图像范围内（防止超出边界）
    x1 = max(1, x1);
    y1 = max(1, y1);
    x2 = min(size(DOLP_matrix, 2), x2);
    y2 = min(size(DOLP_matrix, 1), y2);
    
    % 提取选中区域的DOLP值
    selected_region = DOLP_matrix(y1:y2, x1:x2);
    
    % 处理NaN值：标记非NaN值并将NaN设为0
    non_nan_mask = ~isnan(selected_region);
    selected_region(isnan(selected_region)) = 0; % NaN值设为0
    
    % 根据区域类型生成有效像素掩码
    if is_background
        % 背景区域：有效像素 = 非NaN且≤10（原逻辑保留）
        over_threshold_mask = selected_region > 10;
        valid_mask = non_nan_mask & ~over_threshold_mask;
        selected_region(over_threshold_mask) = 0;
    else
        % 粒子区域：有效像素 = 非NaN且>0（原逻辑保留）
        valid_mask = non_nan_mask & (selected_region > 0);
    end
    
    % 计算有效像素数量（仅统计有效掩码为1的像素）
    valid_count = sum(valid_mask(:));
    
    % 计算平均偏振度（仅用有效像素）
    if valid_count > 0
        total_sum = sum(selected_region(valid_mask));
        mean_dolp = total_sum / valid_count;
    else
        mean_dolp = 0; % 极端情况：无有效像素时返回0
    end
    
    % 在图像上标记框选区域和结果
    hold on;
    rectangle('Position', [x1, y1, width, height], 'EdgeColor', 'red', 'LineWidth', 2);
    text(x1, y1-10, sprintf('平均DOLP: %.4f', mean_dolp), ...
         'Color', 'red', 'BackgroundColor', 'white', 'FontWeight', 'bold');
    hold off;
end

% 函数2：计算平均偏振角（核心修改：新增is_process_05参数，控制是否处理0.5）
% 输入参数新增：is_process_05（布尔值）- true=粒子（排除0.5）；false=背景（保留0.5）
function [mean_AOPNorm, mean_AOP_deg, valid_count] = calc_mean_angle(AOPNormalized, fig_title, is_process_05)
    % 显示偏振角图像
    figure('Name', fig_title);
    imshow(AOPNormalized);
    title([fig_title, '（拖动鼠标框选区域，完成后按Enter）']);
    colormap(jet);
    colorbar;
    caxis([0, 1]); % 固定色标范围，确保粒子/背景图对比一致
    
    % 交互式框选区域
    h_rect = imrect;
    rect_pos = wait(h_rect);
    
    % 提取并修正坐标（防止超出图像范围）
    x1 = round(rect_pos(1));
    y1 = round(rect_pos(2));
    width = round(rect_pos(3));
    height = round(rect_pos(4));
    x2 = x1 + width - 1;
    y2 = y1 + height - 1;
    
    img_rows = size(AOPNormalized, 1);
    img_cols = size(AOPNormalized, 2);
    x1 = max(1, x1);
    y1 = max(1, y1);
    x2 = min(img_cols, x2);
    y2 = min(img_rows, y2);
    
    % 提取选中区域数据
    selected_AOPNorm = AOPNormalized(y1:y2, x1:x2);
    
    % ---------------------- 核心修改：分规则处理0.5值 ----------------------
    % 1. 先排除NaN值（所有区域均需排除）
    non_nan_mask = ~isnan(selected_AOPNorm);
    selected_AOPNorm_processed = selected_AOPNorm;
    selected_AOPNorm_processed(~non_nan_mask) = 0; % NaN设为0（不影响有效像素统计）
    
    % 2. 根据区域类型决定是否排除0.5值
    if is_process_05
        % 粒子区域：排除0.5值（原逻辑保留）
        not_05_mask = abs(selected_AOPNorm - 0.5) > 1e-6; % 浮点数容错
        valid_mask = non_nan_mask & not_05_mask;
    else
        % 背景区域：不排除0.5值（仅排除NaN）
        valid_mask = non_nan_mask;
    end
    
    % 计算有效像素数量和平均值
    valid_count = sum(valid_mask(:));
    if valid_count > 0
        % 仅用有效像素计算平均值
        mean_AOPNorm = sum(selected_AOPNorm_processed(valid_mask)) / valid_count;
        mean_AOP_deg = mean_AOPNorm * 180 - 90; % 归一值→实际角度（-90°~90°）
    else
        mean_AOPNorm = 0;
        mean_AOP_deg = 0;
        fprintf('⚠️  警告：%s所选区域无有效像素（全为NaN）\n', fig_title);
    end
    
    % 在图像上标记结果（补充有效像素数显示）
    hold on;
    rectangle('Position', [x1, y1, width, height], 'EdgeColor', 'red', 'LineWidth', 2);
    text_content = sprintf('平均AOP: %.4f\n实际角度: %.1f°\n有效像素: %d', ...
        mean_AOPNorm, mean_AOP_deg, valid_count);
    text_y = max(20, y1 - 50); % 避免文字超出图像顶部
    text(x1, text_y, text_content, ...
        'Color', 'red', 'BackgroundColor', 'white', 'FontSize', 10, 'FontWeight', 'bold');
    hold off;
end