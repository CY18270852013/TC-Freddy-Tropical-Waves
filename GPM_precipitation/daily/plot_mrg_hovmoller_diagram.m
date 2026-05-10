clear;clc;
filename = 'E:\Results_of_Freddy_ChenYong_version2\GPM_anomaly_daily\GPM_anomaly_for_MRG_daily_20220901_20230630.nc';

lon = ncread(filename, 'lon');
lat = ncread(filename, 'lat');
time = ncread(filename, 'time');
mrg_data = ncread(filename, 'mrg'); % 维度: lon x lat x time

lon_range = [0, 180];
lon_idx = find(lon >= lon_range(1) & lon <= lon_range(2));
lat_range = [-10, 10];
lat_idx = find(lat >= lat_range(1) & lat <= lat_range(2));
start_date = datenum(2023, 1, 1);
end_date = datenum(2023, 3, 31);
% 时间变量是datenum格式，直接使用
date_series = time;
time_idx = find(date_series >= start_date & date_series <= end_date);

subset_data = mrg_data(lon_idx, lat_idx, time_idx);
% 计算纬度平均（10°S~10°N）
lat_mean_data = mean(subset_data, 2, 'omitnan');
lat_mean_data = squeeze(lat_mean_data);
% 转置数据以便时间在纵轴，经度在横轴
hovmoller_data = lat_mean_data';

% 绘制Hovmöller图
plot_lon = lon(lon_idx);
plot_dates = date_series(time_idx);
figure('Position', [100, 100, 1200, 600]);
pcolor(plot_lon, plot_dates, hovmoller_data);
shading flat;
colormap(jet(20));
colorbar;
xlabel('Longitude (°E)', 'FontSize', 12);
ylabel('Date', 'FontSize', 12);
title('Time-Longitude MRG Hovmöller Diagram: Precipitation Anomaly (10°S-10°N)', 'FontSize', 14);
y_ticks = min(plot_dates):5:max(plot_dates);
set(gca, 'YTick', y_ticks);
datetick('y', 'mm/dd', 'keepticks');
grid on;
set(gca, 'FontSize', 11);
set(gca, 'Layer', 'top');
saveas(gcf, 'mrg_hovmoller_diagram_10S_10N.png', 'png');
fprintf('绘图完成！\n');