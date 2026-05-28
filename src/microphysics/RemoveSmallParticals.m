function result = RemoveSmallParticals(a1)
     
    
     jl=zeros(size(a1,1),1);%两粒子二维质心间的距离-两个粒子的半径
%      k=find(max(a1_d));%粒子本体等效直径最大
if ~isempty(jl) == 1
     a1=sortrows(a1,-4);
     a1_x=a1(:,1);
     a1_y=a1(:,2);
     a1_d=a1(:,4);
     
     for  k=1:1:size(a1,1)
             for t=1:1:size(a1,1)-k
                    jl(k+t)=sqrt((a1_x(k)-a1_x(k+t))^2+(a1_y(k)-a1_y(k+t))^2);
%                     Cz(k+t) = jl-a1_d(k)/2-a1_d(k+t)/2;

                    if abs(jl(k+t)) <= 0.1 %需调整
                        a1(k+t,:) = [0 0 0 0 0 0 0 0 0];
                    end
             end
     end
     
      a1(all(a1==0,2),:)=[];         %%删除置0的行数
      result = a1;
end