clear;clc;
filename = 'E:\科研\热带气旋Freddy极端长生命史原因探究\Processed_Data_of_Freddy\GPM_anomaly_daily\GPM_anomaly_for_MJO_daily_20220901_20230630.nc';

lon = ncread(filename, 'lon');
lat = ncread(filename, 'lat');
time = ncread(filename, 'time');
mjo_data = ncread(filename, 'mjo'); % 维度: lon x lat x time

lon_range = [0, 180];
lon_idx = find(lon >= lon_range(1) & lon <= lon_range(2));
lat_range = [-10, 10];
lat_idx = find(lat >= lat_range(1) & lat <= lat_range(2));
start_date = datenum(2023, 1, 1);
end_date = datenum(2023, 3, 31);
% 时间变量是datenum格式，直接使用
date_series = time;
time_idx = find(date_series >= start_date & date_series <= end_date);

subset_data = mjo_data(lon_idx, lat_idx, time_idx);
% 计算纬度平均（10°S~10°N）
lat_mean_data = mean(subset_data, 2, 'omitnan');
lat_mean_data = squeeze(lat_mean_data);
% 转置数据以便时间在纵轴，经度在横轴
hovmoller_data = lat_mean_data';

% ====================== 核心修改：自定义色标定义 ======================
% 1. 离散色标节点：从色条底部(最小值)到顶部(最大值)的归一化RGB值，1:1匹配你提供的颜色柱
custom_cmap_discrete = [
    0.0000    0.0627    0.2510;  % 最底部：藏蓝（最小值）

    0.0627    0.3765    0.7529;  % 中深蓝
    0.3765    0.6275    0.8784;  % 中蓝
    0.6902    0.8784    0.9412;  % 浅蓝

    1.0000    1.0000    1.0000;  % 中间：白色（0值）

    1.0000    0.6902    0.6275;  % 浅橙
    1.0000    0.3765    0.2510;  % 橙色
    0.8157    0.0627    0.0627;  % 亮红

    0.3137    0.0000    0.0000;  % 最顶部：深暗红（最大值）
];

% 2. 可选：生成20阶平滑渐变色标（和原代码jet(20)色阶数一致，过渡更自然）
n_color_level = 9;
x_node = linspace(0, 1, size(custom_cmap_discrete, 1));
x_interp = linspace(0, 1, n_color_level);
custom_cmap_smooth = interp1(x_node, custom_cmap_discrete, x_interp);

% 3. 选择最终使用的色标：离散分块用custom_cmap_discrete，平滑渐变用custom_cmap_smooth
use_cmap = custom_cmap_smooth; 
% =====================================================================

% 绘制Hovmöller图
plot_lon = lon(lon_idx);
plot_dates = date_series(time_idx);
figure('Position', [100, 100, 1200, 600]);
pcolor(plot_lon, plot_dates, hovmoller_data);
shading flat;


% ====================== 色标应用与优化 ======================
colormap(use_cmap);  % 应用自定义色标
% 强制对称色标范围，确保0值精准对应中间白色，符合异常场绘图规范
max_abs_val = max(abs(hovmoller_data(:)), [], 'omitnan');
caxis([-max_abs_val, max_abs_val]);
colorbar;  % 显示匹配的色条
% ===========================================================



xlabel('Longitude (°E)', 'FontSize', 12);
ylabel('Date', 'FontSize', 12);
title('Time-Longitude MJO Hovmöller Diagram: Precipitation Anomaly (10°S-10°N)', 'FontSize', 14);
y_ticks = min(plot_dates):5:max(plot_dates);
set(gca, 'YTick', y_ticks);
datetick('y', 'mm/dd', 'keepticks');
grid on;
set(gca, 'FontSize', 11);
set(gca, 'Layer', 'top');
saveas(gcf, 'mjo_hovmoller_diagram_10S_10N.png', 'png');
fprintf('绘图完成！\n');