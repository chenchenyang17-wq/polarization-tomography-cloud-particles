function[wid, hei]=minboxing(d_x,d_y)
dd = [d_x, d_y];
dd1 = dd([4 1 2 3],:);
ds = sqrt(sum((dd-dd1).^2,2)); %三角形勾股定理
wid = min(ds(1:2));
hei = max(ds(1:2));
end