function c=mix_a7(iii,Path)
 %Step1：定义文件路径参数

Folder=[Path,'output1st\',num2str(iii),'\'];  %%设置读取再现图所在文件夹的路径
Folder_result=[Path,'output2nd\',num2str(iii),'\'];  %%设置粒子识别图的输出文件夹路径
Folder_result1=[Path,'output3rd\',num2str(iii),'\'];  %%设置粒子红框标记图的输出文件夹路径
Folder_result2=[Path,'output4th\',num2str(iii),'\'];  %%设置35个重建距离对应的35个Excel的输出文件夹路径。
Folder_result3=[Path,'output6th\',num2str(iii),'\'];%%设置输出文件夹位置%%设置输出文件夹位置

Depth_range=[179 185];  %%手动定义全息图重建距离范围，单位mm
Depth_steps=7;       %%步长设定为5，共35个重建距离

if Depth_steps==1
    Slice_depths=Depth_range(1);
else    
    Slice_depths=linspace(Depth_range(1),Depth_range(2), Depth_steps);    %%将重建距离定义成5：5：175的形式。
end

%Step2：对再现图处理
for Reconstruction_distance=Slice_depths  %%%%对35个重建距离循环处理
if(Reconstruction_distance>=0&&Reconstruction_distance<1000)%&&(~rem(Reconstruction_distance,1))) %%对重建距离进行判定，必须为正整数。
        Pathbg=[Folder,'Rec_distance_',num2str(Reconstruction_distance),'.bmp'];               %%设置读取再现图的完整路径
        Hologram=(imread(Pathbg));                                                             %% MATLAB读入图像

%对再现图进行二值化处理
Pic2=im2bw(Hologram,0.05);%%自己设定阈值为0.2，将再现图进行二值化

         se=strel('square',3);    %%设置腐蚀所用的方形模板
         se1=strel('square',2);   %%设置膨胀所用的方形模板

         Pic2=imerode(Pic2,se);    %腐蚀
         Pic2=imdilate(Pic2,se1);  %膨胀
         Pic2=imdilate(Pic2,se1);  %腐蚀
         Pic2=imerode(Pic2,se);    %腐蚀

         Pic2 = imfill(Pic2, 'holes');   %%经腐蚀膨胀后获得了粒子的边缘，需要用填洞程序将粒子内部填充为1。 

%寻找4联通域，圈出一定大小区域
[L,N]=bwlabel(Pic2,4);     %%按照4联通域对粒子进行贴标签，L中存放每个粒子的数值矩阵。
s = regionprops(L,'Area'); %%获取每个粒子的像素总数
Pic2=ismember(L,find([s.Area]>=12& [s.Area]<=20000  ));%%根据每个粒子的像素总数对粒子进行删减。

s = regionprops(Pic2,'Area');%%重新获取每个粒子的像素总数
Len = regionprops(Pic2,'Perimeter');%粒子的周长(像素个数)

%%%%%%%%%%%%%%%%%%%%
figure;
imagesc(Pic2);colormap(gray);   %%显示粒子识别图
 axis image;axis off;
 set(gca,'XTick',[])     % Remove the ticks in the x axis!
 set(gca,'YTick',[])      % Remove the ticks in the y axis
 set(gca,'Position',[0 0 1 1]) % Make the axes occupy the hole figure
 set(gcf,'position',[0,0,1000,1000])
  
 status=regionprops(Pic2,'BoundingBox');  %%status中存放包含粒子的最小长方形矩阵。
 box = cat(1,status.BoundingBox);
 status_2=regionprops(Pic2,'ConvexImage');
 centroid = regionprops(Pic2,'Centroid'); %%centroid 中存放每个粒子的质心坐标（x，y）。
 
 hold on;  
 
 [N,m]=size(status);   %%计算当前再现距离粒子的个数 
  c = zeros(N,1);centroid1=zeros(N,1);centroid2=zeros(N,1);c1=zeros(N,1);c2=zeros(N,1);c=zeros(N,1);djx_num=zeros(N,1);%%定义三个空矩阵，用于存放粒子的X轴、Y轴坐标和粒子的长短轴。
  Ss=[];Ls=[];%事先设置存储雪花周长和面积像素数的矩阵
  Rect=[];

 if  N~=0&&N<120        %%判定粒子个数在0到120之间，如果超出这个范围就不处理这个重建距离了。
   B=bwboundaries(Pic2,8,'noholes');%%跟踪二值化图像的外边界
 for t=1:1:N
    boundary=B{t};
    [rx,ry,area]=minboundrect(boundary(:,2),boundary(:,1),'a');
    rect = box(t,1:4);%左上角的X坐标、左上角的Y坐标、宽度（在X轴方向上的长度）、高度（在Y轴方向上的长度）
    Rect(t,:) = [rect(1,1)-rect(1,4)*0.5 rect(1,2)-rect(1,4)*0.5 ceil(rect(1,3)+rect(1,4)) ceil(rect(1,4)*2)];
    Pathbg=[Path,'1\','减背景','.bmp'];
    Hologram=imread(Pathbg);
    cutPic = imcrop(Hologram,Rect(t,:));
    c(t)=sqrt(s(t).Area*3.45*3.45/pi)*2/5;%直径(um)
    hold on;
    line(rx,ry,'Color','r','LineWidth',0.5);
    [wid, hei] = minboxing(rx(1:end-1),ry(1:end-1)); %最小外接矩形
    c1(t,1)= (wid*3.45)/5;%短轴(um)
    c2(t,1)= (hei*3.45)/5;%长轴(um)
    centroid1(t,1)=centroid(t,1).Centroid(1,1)*3.45/1000/5;    %%计算粒子的X轴坐标mm
    centroid2(t,1)=centroid(t,1).Centroid(1,2)*3.45/1000/5;      %%计算粒子的Y轴坐标mm
    imwrite(cutPic,strcat(Folder_result3,num2str(Reconstruction_distance),'mm粒子识别','x',num2str(round(centroid1(t,1),4)),'y',num2str(round(centroid2(t,1),4)),'.bmp'));
    text(centroid(t,1).Centroid(1,1)-15,centroid(t,1).Centroid(1,2)-15,num2str(t),'Color', 'r','Fontsize',10) %%对每个粒子用红色数字标记
    
    djx_num(t,1)=round(sqrt(wid^2+hei^2));
 end

 for i = 1:1:N
     tn = status_2(i).ConvexImage;
     Sout = regionprops(tn, 'Area');
     Num_2(i) = Sout.Area;
     Ss(i) = Num_2(i)*3.45^2/25;%面积um2
 end

 for i=1:1:N
     Ls(i)=Len(i).Perimeter;            
     Ls(i)= (Ls(i)*3.45)/5;%周长um
 end

 saveas(gcf,strcat(Folder_result1,num2str(Reconstruction_distance),'mm红框标记图','.bmp'));%%将标记好红框和红色数字的粒子识别图保存为粒子红框标记图
 a1=[];          %%定义空矩阵用于存放粒子Z轴坐标
 a1(1:N)=Reconstruction_distance/25;%Z轴坐标mm
 Roundness = [(4 * pi * Ss) ./ (Ls.^2)];%圆度
 %F=(Ls.* c2)./Ss;
 %c3=(c1+c2)/2;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%将X、Y、z轴坐标和长短轴矩阵转换为列向量
  %centroid1=centroid1';%X坐标mm
  %centroid2=centroid2';%Y坐标mm
  a1=a1';%Z坐标mm
  %c=c';
  %c1=c1';     
  %c2=c2';
  Ls = Ls';
  Ss = Ss';
  Roundness = Roundness';%圆度

 %cen_cl=[centroid1,centroid2,a1,c,c1,c2,F, Sum_gs, Ss];  %%X、Y、Z轴坐标和长短轴矩阵整合为一个矩阵
 %cen_cl=[centroid1,centroid2,a1,c,c1,c2,F,Ss,Ls,c3]; %Sc面积um2 Ls周长um
 %cen_cl=[centroid1,centroid2,a1,c,c1,c2,Rect,F];
 cen_cl=[centroid1,centroid2,a1,c,c1,c2,Roundness,Ls,Ss];%X坐标mm、Y坐标mm、Z坐标mm、直径um、短轴(宽)um、长轴(高)um、圆度、周长um、面积um2
 %F = [];
 Pic2=Pic2+0;        %%将粒子识别图像的矩阵由二值矩阵转换为灰度矩阵
 imwrite(Pic2,strcat(Folder_result,num2str(Reconstruction_distance),'mm粒子识别','.bmp'));       %%输出粒子识别图
 
             result = RemoveSmallParticals(cen_cl);

             csvwrite(strcat(Folder_result2,num2str(Reconstruction_distance),'mm粒子识别','.csv'),result); %%输出X、Y、Z轴坐标和直径矩阵到Excel表
         else
             csvwrite(strcat(Folder_result2,num2str(Reconstruction_distance),'mm粒子识别','.csv'),[0 0 0 0 0 0 0 0 0]);  %%对于粒子个数在0到8范围之外的重建距离，输出[0 0 0 0]。
         end
  close all

end
end
c=0;
