function b=zaixianchengxu_aa0(ii1,Path)
 %Step1：定义文件参数
Folder1=[Path,num2str(ii1),'\'];  %%设置所需要处理系列全息图所在文件夹位置
Folder_result1=[Path,'output1st\'];   %存储再现结果的文件夹

 %Step2：对数字全息图进行数值重建，
Hologramb=zeros(2048,2448);  %设置背景全息照片大小

%%%循环读入五张背景全息图
for a1=1:1:10
% for a1=Hologram_name1+1:Hologram_name1+10
    Hologram_name_b1=a1;    
    File_stringb1=[Folder1,'1 (',num2str(Hologram_name_b1),')']; %拼接读入背景全息图的绝对路径
    Hologramb1=(imread([File_stringb1,'.bmp'])); % MATLAB读入图像
    Hologramb1=double(Hologramb1); %将读入的全息图片矩阵数据类型变为double（双精度）类型

    Hologramb=Hologramb+Hologramb1; %将读入的全息图矩阵与Hologramb矩阵相加，并将相加结果又赋给Hologramb
end
Hologram1=Hologramb/10; %将五张图片相加的结果取平均
% Hologramb1=(imread("E:\标定实验\判焦标定\20um\背景.bmp"));
% Hologram1=double(Hologramb1);
%读入全息图
File_string=[Folder1,'原图']; %拼接读入全息图的绝对路径
Hologram2=(imread([File_string,'.bmp'])); % MATLAB读入图像
Hologram2=double(Hologram2); %将读入的全息图片矩阵数据类型变为double（双精度）类型
% 
% File_string=[Folder1,'Mono8_135_Degree_15_15_46']; %拼接读入全息图的绝对路径
% Hologram1=(imread([File_string,'.bmp'])); % MATLAB读入图像
% Hologram1=double(Hologram1); %将读入的全息图片矩阵数据类型变为double（双精度）类型
Hologram=Hologram2-Hologram1; %将读入的全息图减去背景
Hologram3=mat2gray(Hologram,[min(Hologram(:)),1*max(Hologram(:))]);   %%对强度矩阵进行归一化。
imwrite(Hologram3,strcat(Folder1,'减背景','.bmp'));

% imshow(Hologram)
% % min(min(Hologram))
[xx,yy]=size(Hologram);  %%获得图像的尺寸
% Hologram=Hologram+63.1;
%   Hologram2=mat2gray(Hologram2,[min(Hologram2(:)),1*max(Hologram2(:))]);
      % imwrite(Hologram,'E:\标定实验\判焦标定\20um\减背景.bmp');
%%傅里叶变换，得到频谱信息  

Frequency=fftshift(fft2(Hologram));%%傅里叶变换，得到频谱信息



% Step3：定义实验参数
             
%%定义激光波长、CCD等参数
format long
lambda=638e-9;  %%激光波长，单位米
delta=3.45e-6;  %%CCD像素尺寸
CCD_Sizex=delta*xx;  %%CCD横向尺寸
CCD_Sizey=delta*yy;  %%CCD纵向尺寸


%%%sa'z%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Depth_range=[179 185];  %%手动定义全息图重建距离范围，单位mm
Depth_steps=7;      %%定义全息图重建距离的步长为1。
if Depth_steps==1
    Slice_depths=Depth_range(1);
else    
    Slice_depths=linspace(Depth_range(1),Depth_range(2), Depth_steps);%%将重建距离定义成0：1：180的形式。
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Step4：设定传递函数并数值重建
Wavefront=(Frequency);
[nn,mm]=meshgrid(1:yy,1:xx); %%设定渐变矩阵  水平方向为mm 竖直方向为nn
for Reconstruction_distance=(Slice_depths/1000)  %%循环数值重建

    if Reconstruction_distance==0
        H=1;%%设定传递函数H
        Reconstruction_field=ifft2(fftshift(Wavefront));
    else
        H=exp(1i*2*pi*Reconstruction_distance*sqrt((1/lambda).^2-((mm-xx/2)/CCD_Sizex).^2-((nn-yy/2)/CCD_Sizey).^2)); %%设定传递函数H
        Reconstruction_field=ifft2(fftshift(Wavefront.*H));%%将频谱矩阵与传递函数相乘，随后利用fftshift将零频点移到中间，再进行傅里叶逆变换。
    end
    Intensity=(abs(Reconstruction_field)).^2; %%重建物光波的强度图
    %保存图像    
    I=mat2gray(Intensity,[min(Intensity(:)),1*max(Intensity(:))]);   %%对强度矩阵进行归一化。
%     imshow(I);
%     img = im2bw(I,0.75);
%     imshow(img);
    imwrite(I,strcat(Folder_result1,num2str(ii1),'\','Rec_distance_',num2str(Reconstruction_distance*1000),'.bmp')); %%将归一化后的再现图保存，名称为Rec_distance_重建距离的值。
     b=0;
end

