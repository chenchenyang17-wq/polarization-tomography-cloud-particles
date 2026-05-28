function zaixianchengxu_aa1()  % 修正函数定义，便于直接调用
    % Step1：定义基础文件参数（新增减背景图保存文件夹）
    Folder = 'F:\E (2)\E\input9\4.bmp\原图\';          % 4张全息图所在文件夹
    Folder1 = 'F:\E (2)\E\input9\2.bmp\背景\';          % 所有背景图所在文件夹（共用此路径）
    Folder_result1 = 'F:\E (2)\E\input9\4.bmp\再现后\';  % 重建结果根文件夹
    % 新增：减背景后图片的保存文件夹（可根据需求修改路径
    Folder_sub_bg = 'F:\E (2)\E\input9\4.bmp\剪完背景后\';  
    
    bg_count = 10;                                  % 关键修改：每张全息图对应10张背景图
    holo_total = 4;                                 % 需处理的全息图总数（4张）

    % ######################## 关键：定义4张全息图的文件名（不含.bmp） ########################
    holo_names = {
        '0',  % 第1张全息图文件名
        '45', % 第2张全息图文件名
        '90', % 第3张全息图文件名
        '135', % 第4张全息图文件名
    };
    % #########################################################################################

    % 新增：创建减背景后图片的保存文件夹（不存在则自动创建）
    if ~exist(Folder_sub_bg, 'dir')
        mkdir(Folder_sub_bg);
        fprintf('已创建减背景后图片保存文件夹：%s\n\n', Folder_sub_bg);
    end

    % Step2：循环处理4张全息图（1~4对应子文件夹1~4）
    for i = 1:holo_total
        fprintf('开始处理第%d张全息图：%s\n', i, holo_names{i});

        % ---------------------- 1. 创建当前全息图的重建结果子文件夹 ----------------------
        save_subfolder = fullfile(Folder_result1, num2str(i));  
        if ~exist(save_subfolder, 'dir')  
            mkdir(save_subfolder);
            fprintf('  创建重建结果子文件夹：%s\n', save_subfolder);
        end

        % ---------------------- 2. 读取当前全息图对应的10张背景图并求平均 ----------------------
        Hologramb = zeros(1024, 1224);  % 初始化背景累加矩阵
        for a1 = 1:bg_count  % 循环读取1-10张背景图
            bg_file_name = [Folder1, num2str(i), ' (', num2str(a1), ')'];
            Hologramb1 = imread([bg_file_name, '.bmp']);  
            Hologramb1 = double(Hologramb1);              
            Hologramb = Hologramb + Hologramb1;           
        end
        Hologram_bg_avg = Hologramb / bg_count;  % 关键修改：10张背景图平均值
        % ---------------------- 3. 读取当前全息图并减去背景 ----------------------
        holo_file_name = fullfile(Folder, holo_names{i});
        Hologram_original = imread([holo_file_name, '.bmp']);  
        Hologram_original = double(Hologram_original);          
        Hologram_sub_bg = Hologram_original - Hologram_bg_avg;  % 核心：全息图减背景
        % ---------------------- 新增：保存减背景后的图片 ----------------------
        % 1. 对减背景后的图像归一化（避免数值范围异常导致保存失真）
        Hologram_sub_bg_norm = mat2gray(Hologram_sub_bg);  % 归一到0~1范围
        Hologram_sub_bg_uint8 = uint8(Hologram_sub_bg_norm * 255);  % 转换为8位图像格式（bmp常用）
        % 2. 构建保存路径：文件夹 + 原文件名 + "_sub_bg.bmp"（明确标识是减背景图）
        sub_bg_save_path = fullfile(Folder_sub_bg, [holo_names{i}, '_sub_bg.bmp']);
        % 3. 保存图片
        imwrite(Hologram_sub_bg_uint8, sub_bg_save_path);
        fprintf('  已保存减背景后图片至：%s\n', sub_bg_save_path);

        % ---------------------- 4. 傅里叶变换（原逻辑不变） ----------------------
        [xx, yy] = size(Hologram_sub_bg);  
        Frequency = fftshift(fft2(Hologram_sub_bg));  

        % ---------------------- 5. 实验参数（原逻辑不变） ----------------------
        format long;
        lambda = 638e-9;    % 激光波长（米）
        delta = 3.45e-6;    % CCD像素尺寸（米）
        CCD_Sizex = delta * xx;  % CCD横向尺寸
        CCD_Sizey = delta * yy;  % CCD纵向尺寸

        % 重建距离参数（原逻辑不变，当前为0~34mm，35步）
        Depth_range = [0 34];
        Depth_steps = 51;
        if Depth_steps == 1
            Slice_depths = Depth_range(1);
        else
            Slice_depths = linspace(Depth_range(1), Depth_range(2), Depth_steps);
        end

        % ---------------------- 6. 数值重建与结果保存（原逻辑不变） ----------------------
        Wavefront = Frequency;
        [nn, mm] = meshgrid(1:yy, 1:xx);  

        for Reconstruction_distance = (Slice_depths / 1000)
            if Reconstruction_distance == 0
                H = 1;%%设定传递函数H
                Reconstruction_field = ifft2(fftshift(Wavefront));
            else
                H=exp(1i*2*pi*Reconstruction_distance*sqrt((1/lambda).^2-((mm-xx/2)/CCD_Sizex).^2-((nn-yy/2)/CCD_Sizey).^2));%%设定传递函数H
                Reconstruction_field = ifft2(fftshift(Wavefront .* H));%%将频谱矩阵与传递函数相乘，随后利用fftshift将零频点移到中间，再进行傅里叶逆变换。
            end
            Intensity = (abs(Reconstruction_field)).^2;%%重建物光波的强度图
            I = mat2gray(Intensity, [min(Intensity(:)), 1*max(Intensity(:))]);
            save_path = strcat(save_subfolder, '\', 'Rec_distance_', num2str(Reconstruction_distance*1000), '.bmp');
            imwrite(I, save_path);
        end

        fprintf('第%d张全息图处理完成！重建结果保存至：%s\n\n', i, save_subfolder);
    end

    fprintf('所有4张全息图【减背景保存+重建】任务全部完成！\n');
    fprintf('减背景后图片汇总路径：%s\n', Folder_sub_bg);
end
