function f=RemoveDuplicateParticals4(j,Path)


Folder_result=[Path,'output4th\'];  %%设置读取的Excel表所在文件夹位置
Folder_result2=[Path,'输出\'];      %%设置输出文件夹位置
Folder_result3=[Path,'output5th\'];
Folder_result4=[Path,'output6th\'];%%设置输出文件夹位置%%设置输出文件夹位
Folder_result5=[Path,'判焦前\'];
a2=[];             %%设置空矩阵，存放35个Excel表的数据


for i=179:1:185 %%依次读取35个Excel表
    f = [Folder_result,num2str(j),'\',num2str(i),'mm粒子识别.csv'];
    a1=csvread(f);  %%读取第j个文件夹下的Excel表（35个）
%     a1=csvread(strcat(Folder_result2,'1 (',num2str(i),').csv'));  %%读取第j个文件夹下的Excel表（35个）
    a2=[a2;a1];         %%将Excel表首尾拼接，拼成一个四列的大矩阵。
    a1=[]; 
end
a2(all(a2==0,2),:)=[];%去全零行
% csvwrite(strcat(Folder_result2,'不去重',num2str(j),'.csv'),a2);  %%将a2输出保存为Excel表，这是最终结果之一。
bb3 = [];bb4 = [];

for m=1:1:length(a2(:,1))
    if(isempty(a2)) %% 判定a2矩阵是否为空，为空则跳出循环；反之继续循环直至a2矩阵为空
        break;
    end
    bb3 = a2(1,:);
    for n=1:1:length(bb3(:,1))
     if(bb3(1,1) <= 0.1 || bb3(1,2) <=0.1)
          bb3(1,:) = [0 0 0 0 0 0 0 0 0];
          bb3(1,:) = bb3(1,:);
     elseif(bb3(1,1) >= 2.01 || bb3(1,2) >=2.01)
        
            bb3(1,:) = [0 0 0 0 0 0 0 0 0];
        
            bb3(1,:) = bb3(1,:);
%      elseif(bb3(1,4) < 5 && bb3(1,11) < 0.5)
%            bb3(1,:) = [0 0 0 0 0 0 0 0 0 ];
%         
%             bb3(1,:) = bb3(1,:);
     else
        bb3(1,:) = bb3(1,:);
     end
    bb4 = [bb4;bb3(1,:)];
    a2(n,:) = [];
    bb3 = [];
    end
end

bb4(all(bb4==0,2),:)=[];

a2 = bb4;
bb1=[]; %%设置空矩阵，用于存放每个粒子对应的所有重复粒子(包括自身)
res = [];%%设置空矩阵用于存放去重结果
bb5=[];
if(~isempty(a2))
for g=1:length(a2(:,1))
    if(isempty(a2)) %% 判定a2矩阵是否为空，为空则跳出循环；反之继续循环直至a2矩阵为空
        break;
    end
    bb1(1,:) = a2(1,:); %% 每次外层循环将a2矩阵的第一行数据赋给bb1矩阵
    for k=1:length(a2(:,1)) %% 用于找出a2矩阵中所有与bb1相重复的粒子
         if(abs(bb1(1,1)-a2(k,1))<0.12 && abs(bb1(1,2)-a2(k,2))<0.12) %%每行粒子的X、Y轴坐标都与bb1第一行粒子的X、Y轴坐标比较，两个差值都小于0.02，就认为这一行粒子是重复粒子
%         if(sqrt((bb1(1,1)-a2(k,1))^2+(bb1(1,2)-a2(k,2))^2)<0.07)
            bb1= [bb1;a2(k,:)]; %% 如果重复将a2矩阵这行数据加入到bb1矩阵中
            if(~isempty(bb1))
               [e,i,a] = unique(bb1(:,3),'rows');
                bb1=bb1(i,:);
                e=[];a=[];
            end
            a2(k,:)=[0 0 0 0 0 0 0 0 0];  %% 再将a2矩阵这行数据置零
        end
    end
    bb1=sortrows(bb1,3);
    bb5 = [bb5;bb1];
    a2(all(a2==0,2),:)=[]; %% 删去a2矩阵中''所有为0行
if(size(bb1(:,4),1)>=3 && size(bb1(:,4),1)<=5)
        rows = bb1(:, 4) < 3.5;
        bb1(rows, :) = [];
elseif(size(bb1(:,4),1)>=6 && size(bb1(:,4),1)<=9)
        rows = bb1(:, 4) < 5;
        bb1(rows, :) = [];
elseif(size(bb1(:,4),1) >=10 && size(bb1(:,4),1) <=20)
        rows = bb1(:, 4) < 10;
        bb1(rows, :) = [];
elseif(size(bb1(:,4),1) >=21 && size(bb1(:,4),1) <=35)
        rows = bb1(:, 4) < 12;
        bb1(rows, :) = [];
else
       bb1 = bb1;
end
if(~isempty(bb1))
           group={};
            current_group = 1;  
            start_index = 1;  
            for i = 2:length(bb1(:,3))  
                gap = abs(bb1(i,3)-bb1(i-1,3));  
      
    % 检查间隔是否在范围内  
                 if  gap < 0.9 
        % 如果在范围内，继续检查后续元素  
                    continue;  
                 else  
        % 如果间隔不在范围内，则将当前组添加到结果中  
                    group{current_group} =bb1(start_index:i-1,:);  
          
        % 更新当前组和开始索引以开始新的组  
                    current_group = current_group + 1; 
                   start_index = i;  
                 end  
            end  
  
% 添加最后一个组到结果中  
        if start_index <= length(bb1(:,1))  
             group{current_group} = bb1(start_index:end,:);  
        end   
          x= cellfun('size',group,1);%选择数据最多的一组进行处理
          bb1=group{1,find(x==max(x))};
end 
if(~isempty(bb1))
     if(size(bb1(:,4),1)>=1 && size(bb1(:,4),1)<=5)
    % if(size(bb1(:,4),1)==2 )
    
         
                h = ceil((length(bb1(:,1)) + 1)/2);
         
          
           res = [res;bb1(h,:)];

           % [~,index] = max(bb1(:,4));
           % res = [res;bb1(index,:)];

         elseif(size(bb1(:,4),1) >=6 && size(bb1(:,4),1) <=9) 
           % [~,index] = max(bb1(:,4));
           % res = [res;bb1(index,:)];
           
           h=find(bb1(:,4)==min(bb1(:,4)));
           h=h(1,1);
            if(h== 1)
                  bb1(h,4)=mean([bb1(h+1,4),bb1(h,4)]);
            elseif(h == size(bb1(:,4),1))
                   bb1(h,4)=mean([bb1(h-1,4),bb1(h,4)]);
            else
                   bb1(h,4)=mean([bb1(h-1,4),bb1(h,4),bb1(h+1,4)]);
            end
           res = [res;bb1(h,:)]; %% 取出bb1中间一行的数据存入结果矩阵
         
         elseif(size(bb1(:,4),1) >= 10 && size(bb1(:,4),1) <= 20) 
%          h2=find(bb1(:,4)==min(bb1(:,4)));
           h2=find(bb1(:,4)==min(bb1(:,4)));
          if(h2 == 1 || h2 == length(bb1(:,3)))
              bb1(h2,:) = [];
              h2 = find(bb1(:,4)==min(bb1(:,4)));
             if(~isempty(bb1))
               if(h2 == 1 || h2 == length(bb1(:,3)))
                  bb1 = [];
               end
             end
          end
          if(~isempty(bb1))
           h=find(bb1(:,4)==min(bb1(:,4)));   
           h=h(1,1);
               if(bb1(h,4)>=14)
                   if(h == size(bb1(:,4),1))
                        bb1=[bb1(h-2,:);bb1(h-1,:);bb1(h,:)];
                   elseif(h== 1)
                       bb1=[bb1(h,:);bb1(h+1,:);bb1(h+2,:)];
                   elseif(h== 2)  
                       bb1=[bb1(h-1,:);bb1(h,:);bb1(h+1,:);bb1(h+2,:)];
                   elseif(h == size(bb1(:,4),1)-1)
                        bb1=[bb1(h-2,:);bb1(h-1,:);bb1(h,:);bb1(h+1,:)];
                   else
                       bb1=[bb1(h-2,:);bb1(h-1,:);bb1(h,:);bb1(h+1,:);bb1(h+2,:)];
                   end
               % elseif(length(bb1(:,1))>3 && length(bb1(bb1(:,1)<=8)))
               else
                   if(h== 1)
                        bb1=[bb1(h,:);bb1(h+1,:)];
                   elseif(h == size(bb1(:,4),1))
                        bb1=[bb1(h-1,:);bb1(h,:)];
                   else
                        bb1=[bb1(h-1,:);bb1(h,:);bb1(h+1,:)];
                   end
                 %                    bb1(h,4) = bb1(h,4)/1.2;
               end
               h1=find(bb1(:,4)==max(bb1(:,4)));
               res = [res;bb1(h1,:)];
          end
               
       elseif(size(bb1(:,4),1) >= 21 && size(bb1(:,4),1) <= 35) 
%         % [~,index] = max(bb1(:,4));
%         % res = [res;bb1(index,:)];
              h2=find(bb1(:,4)==min(bb1(:,4)));
           if(h2 == 1 || h2 == length(bb1(:,3)))
              bb1(h2,:) = [];
              h2 = find(bb1(:,4)==min(bb1(:,4)));
             if(~isempty(bb1))
               if(h2 == 1 || h2 == length(bb1(:,3)))
                  bb1 = [];
               end
             end
           end   
           if(~isempty(bb1))
            h=find(bb1(:,4)==min(bb1(:,4)));
            h=h(1,1);
               if(bb1(h,4)>=18)
                   if(h == size(bb1(:,4),1))
                        bb1=[bb1(h-3,:);bb1(h-2,:);bb1(h-1,:);bb1(h,:)];
                   elseif(h== 1)
                       bb1=[bb1(h,:);bb1(h+1,:);bb1(h+2,:);bb1(h+3,:)];
                   elseif(h== 2)  
                       bb1=[bb1(h-1,:);bb1(h,:);bb1(h+1,:);bb1(h+2,:);bb1(h+3,:)];
                   elseif(h== 3)  
                       bb1=[bb1(h-2,:);bb1(h-1,:);bb1(h,:);bb1(h+1,:);bb1(h+2,:);bb1(h+3,:)];
                   elseif(h == size(bb1(:,4),1)-1)
                        bb1=[bb1(h-3,:);bb1(h-2,:);bb1(h-1,:);bb1(h,:);bb1(h+1,:)];
                   elseif(h == size(bb1(:,4),1)-2)
                        bb1=[bb1(h-3,:);bb1(h-2,:);bb1(h-1,:);bb1(h,:);bb1(h+1,:);bb1(h+2,:)];
                   else
                       bb1=[bb1(h-3,:);bb1(h-2,:);bb1(h-1,:);bb1(h,:);bb1(h+1,:);bb1(h+2,:);bb1(h+3,:)];
                   end
                   
               % elseif(length(bb1(:,1))>3 && length(bb1(bb1(:,1)<=8)))
               elseif(bb1(h,4)>=14 && (bb1(h,4)<18))
                   if(h == size(bb1(:,4),1))
                        bb1=[bb1(h-2,:);bb1(h-1,:);bb1(h,:)];
                   elseif(h== 1)
                       bb1=[bb1(h,:);bb1(h+1,:);bb1(h+2,:)];
                   elseif(h== 2)  
                       bb1=[bb1(h-1,:);bb1(h,:);bb1(h+1,:);bb1(h+2,:)];
                   elseif(h == size(bb1(:,4),1)-1)
                        bb1=[bb1(h-2,:);bb1(h-1,:);bb1(h,:);bb1(h+1,:)];
                   else
                       bb1=[bb1(h-2,:);bb1(h-1,:);bb1(h,:);bb1(h+1,:);bb1(h+2,:)];
                   end
                   
               else
                  if(h== 1)
                        bb1=[bb1(h,:);bb1(h+1,:)];
                   elseif(h == size(bb1(:,4),1))
                        bb1=[bb1(h-1,:);bb1(h,:)];
                   else
                        bb1=[bb1(h-1,:);bb1(h,:);bb1(h+1,:)];
                   end
                 %                    bb1(h,4) = bb1(h,4)/1.2;
               end
                h1=find(bb1(:,4)==max(bb1(:,4)));
              res = [res;bb1(h1,:)]; 
           end

     end
end
    % res = [res;bb1(ceil(length(bb1(:,1))/2),:)]; %% 取出bb1中间一行的数据存入结果矩阵
    bb1 = []; bb2=[]; res1 = [];
end
end
if(~isempty(res))
[~,ia,~] = unique(res(:,1:2),'rows');
res=res(ia,:);
end
if(~isempty(res))
rows = res(:, 4) < 2.7;
res(rows, :) = [];
end

% rows1 = res(:,11) <=0.5;
% res(rows1,:) = [];


A=all(res==0,2);
res=res(~A,:);
if(~isempty(res))
    for i3=1:length(res(:,1))
        if(res(i3,4) <= 44 || res(i3,4) >= 60)
          res(i3,4)=res(i3,4)*1.004^(res(i3,4));
        else
            res(i3,4)=res(i3,4);
        end
    end
end
if(~isempty(res))
for f = 1:1:length(res(:,1))
  %if(res(f,11) > 5.5 && res(f,4) > 10)
  if(res(f,4) > 10)
    files = dir(fullfile(Folder_result4,num2str(j),'\')); % 获取所有文件，包括子文件夹中的文件（如果需要）  
  
% 初始化一个空数组来存储匹配的文件名  
matchingFiles = []; 
basefilename =  [];
% 要搜索的字符串  
searchString = strcat('x',num2str(round(res(f,1),4)),'y',num2str(round(res(f,2),4)));  
  
% 遍历所有文件，检查文件名是否包含搜索字符串  
for k = 1:length(files)  
    % 忽略子文件夹（如果需要）  
    if ~files(k).isdir  
        % 提取文件名（不包括路径和扩展名）  
        fileName = files(k).name;  
        % 使用strfind检查文件名是否包含搜索字符串  
        if contains(fileName, searchString)
            % 如果找到匹配项，将文件名添加到匹配数组中  
            matchingFiles{end+1} = fullfile(fileName);
%             Pathbg=[Folder_result4,num2str(Reconstruction_distance),'mm粒子识别',matchingFiles,'.bmp'];
%             cut=imread(Pathbg);
%             imwrite(cut,strcat(Folder_result3,num2str(Reconstruction_distance),'mm粒子识别',matchingFiles,'.bmp'));
        end  
    end  
end
% basefilename = regexprep(matchingFiles, '\..*$', '');
if(~isempty(matchingFiles))
 if contains(matchingFiles{1}, '.')  
        % 使用strsplit分割文件名，'.'为分隔符  
        % 注意：如果文件名中有多个'.'，这将分割成多个部分  
        % 我们只对最后一个'.'之后的部分感兴趣，所以使用end-1索引  
        parts = strsplit(matchingFiles{1}, '.');  
        % 将除了最后一个部分之外的所有部分连接起来，形成新的文件名  
        % 使用strjoin函数，并指定'.'作为分隔符（但在这个情况下我们不使用分隔符）  
        % 因为我们实际上想要去掉分隔符  
        % 注意：如果文件名没有'.'，strsplit将返回一个元素数组  
        % 因此，我们需要检查parts的长度
        if length(parts) == 1
            basefilename = regexprep(matchingFiles, '\..*$', '');
        elseif length(parts) > 1  
            basefilename = strjoin(parts(1:end-1), '.'); % 但这里我们实际上不需要'.'作为分隔符  
            % 更简单的方法是直接连接除了最后一个元素之外的所有元素  
            % 因为我们想要的是没有分隔符的版本  
%             basefilename = [parts{1:end-1}]; % 如果parts是cell数组  
            % 或者，如果parts是字符串数组（MATLAB R2016b及更高版本）  
            % baseName = strjoin(parts(1:end-1), '');  
        else  
            % 文件名没有'.'，直接返回原文件名  
            basefilename = matchingFiles;  
        end  
    else  
        % 文件名没有扩展名，直接返回原文件名  
        basefilename = fileName;  
 end 

 f6=[Folder_result4,num2str(j),'\',basefilename,'.bmp'];
 cut=imread(f6);
 imwrite(cut,strcat(Folder_result3,num2str(j),'\',strcat(basefilename,'d',num2str(res(f,4))),'.bmp'));
   end
  end
 end
end
csvwrite(strcat(Folder_result2,num2str(j),'.csv'),res);  %%将a2输出保存为Excel表，这是最终结果之一。
csvwrite(strcat(Folder_result5,num2str(j),'.csv'),bb5);
% csvwrite(strcat(Folder_result2,'融合',num2str(j),'.csv'),res);  %%将a2输出保存为Excel表，这是最终结果之一。
f = 0;
rmdir(strcat(Folder_result4,num2str(j),'\'),'s'); 


