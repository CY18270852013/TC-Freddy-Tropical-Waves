% clear; close all; clc;
% load('rain_mjo.mat');
lat_full = linspace(-30, 30, 602); % 纬度：30°S ~ 30°N
lon_full = linspace(-180, 180, 3600); % 经度：-180° ~ 180°
lat_range = [-30, 10]; % 30°S ~ 10°N
lon_range = [80, 150]; % 80°E ~ 150°E
lat_idx = find(lat_full >= lat_range(1) & lat_full <= lat_range(2));
lon_idx = find(lon_full >= lon_range(1) & lon_full <= lon_range(2));
lat_target = lat_full(lat_idx);
lon_target = lon_full(lon_idx);
start_date = '20230201';
end_date = '20230210';
start_dt = datetime(start_date, 'InputFormat', 'yyyyMMdd');
end_dt = datetime(end_date, 'InputFormat', 'yyyyMMdd');
full_dates = datetime(1998,1,1):datetime(2024,12,31);
target_dates = start_dt:end_dt;
date_indices = ismember(full_dates, target_dates);
target_indices = find(date_indices);

all_precip_data = [];
for i = 1:length(target_indices)
    day_idx = target_indices(i);
    rain_day = squeeze(rain_mjo(lat_idx, lon_idx, day_idx));
    % 只考虑正值
    positive_vals = rain_day(rain_day > 0);
    all_precip_data = [all_precip_data; positive_vals(:)];
end

% 统一数据范围
data_min = 0;
data_max = prctile(all_precip_data, 98); % 使用98%分位数作为最大值，避免异常值影响

%% 创建自定义颜色映射
num_colors = 10;
key_colors = [
    1.0, 1.0, 1.0;   % 纯白色开始
    1.0, 1.0, 0.8;   % 浅黄色
    1.0, 0.95, 0.6;  % 亮黄色
    1.0, 0.9, 0.4;   % 黄色
    1.0, 0.8, 0.2;   % 橙黄色
    1.0, 0.7, 0.0;   % 橙色
    1.0, 0.6, 0.0;   % 红橙色
    1.0, 0.4, 0.0;   % 红色
    0.9, 0.2, 0.0;   % 深红色
    0.8, 0.1, 0.0;   % 暗红色
    0.7, 0.0, 0.0    % 最深红色
];
% 对每个颜色通道进行线性插值
x = linspace(1, size(key_colors, 1), size(key_colors, 1));
xi = linspace(1, size(key_colors, 1), num_colors + 1);
custom_cmap = zeros(num_colors + 1, 3);
for channel = 1:3
    custom_cmap(:, channel) = interp1(x, key_colors(:, channel), xi, 'linear');
end
custom_cmap = max(0, min(1, custom_cmap));

%% 
for i = 1:length(target_indices)
    figure('Position', [100, 100, 1200, 600]);
    day_idx = target_indices(i);
    current_date = target_dates(i);

    rain_day = squeeze(rain_mjo(lat_idx, lon_idx, day_idx));
    rain_day(rain_day <= 0) = NaN;

    [LON, LAT] = meshgrid(lon_target, lat_target);
    contourf(LON, LAT, rain_day, 20, 'LineStyle', 'none');
    colormap(gca, custom_cmap);
    caxis([data_min, data_max]); % 统一颜色轴范围
    colorbar;
    title(sprintf('MJO Precipitation - %s', datestr(current_date, 'yyyy-mm-dd')), ...
          'FontSize', 14, 'FontWeight', 'bold');
    xlabel('Longitude (°E)', 'FontSize', 12);
    ylabel('Latitude (°N)', 'FontSize', 12);
    xlim(lon_range);
    ylim(lat_range);
    grid on;
    filename = sprintf('mjo_precip_%s.png', datestr(current_date, 'yyyymmdd'));
    saveas(gcf, filename);
end