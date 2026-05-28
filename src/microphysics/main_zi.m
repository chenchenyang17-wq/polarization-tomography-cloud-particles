
clc;clear;
Path = 'F:\人影中心\4.23\1\原图1\微物理参数\';

for i = 1:1:1
    b=zaixianchengxu_aa0(i,Path);    %读取全息图，输出不同再现距离下的再现图，再现距离的范围为[0:180]，步长为1，一张全息图对应181张再现图。
    c=mix_a7(i,Path);                             %设定步长为5，范围为[5:175]的再现距离下，对35张再现图分别进行粒子识别，输出每个再现距离对应的粒子三维坐标和粒径，存在EXCEL表中。
    f=RemoveDuplicateParticals4(i,Path);


    close all  
end





