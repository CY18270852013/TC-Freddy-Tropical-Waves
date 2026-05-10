clear; close all; clc;
ncfile = "E:\Data_of_Freddy_ChenYong_vision2\GPM_anomaly_daily\GPM_anomaly_for_MJO_daily_20220901_20230630.nc";
time = ncread(ncfile, 'time');
lat = ncread(ncfile, 'lat');
lon = ncread(ncfile, 'lon');
mjo_data = ncread(ncfile, 'mjo'); % 维度: lon(3600) x lat(400) x time(303)
% 转置为 [纬度, 经度, 时间] 以便绘图
mjo_data = permute(mjo_data, [2, 1, 3]); % 现在维度是: lat(400) x lon(3600) x time(303)
fill_value = -9999.9004;
mjo_data(mjo_data == fill_value) = NaN;
lat_range = [-30, 10]; % 30°S ~ 10°N
lon_range = [80, 150]; % 80°E ~ 150°E
lat_idx = find(lat >= lat_range(1) & lat <= lat_range(2));
lon_idx = find(lon >= lon_range(1) & lon <= lon_range(2));
lat_target = lat(lat_idx);
lon_target = lon(lon_idx);
start_date = '20230201';
end_date = '20230210';
start_dt = datetime(start_date, 'InputFormat', 'yyyyMMdd');
end_dt = datetime(end_date, 'InputFormat', 'yyyyMMdd');
nc_start_date = datetime('20220901', 'InputFormat', 'yyyyMMdd');
full_dates = nc_start_date + days(0:302);
target_dates = start_dt:end_dt;
[~, target_indices] = ismember(target_dates, full_dates);

all_precip_data = [];
for i = 1:length(target_indices)
    day_idx = target_indices(i);
    rain_day = squeeze(mjo_data(lat_idx, lon_idx, day_idx));
    % 只考虑正值
    positive_vals = rain_day(rain_day > 0);
    all_precip_data = [all_precip_data; positive_vals(:)];
end
data_min = 0;  % 最小值设为0
data_max = prctile(all_precip_data, 98);  % 使用98%分位数作为最大值，避免异常值影响

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

%% 绘制每一天的图
for i = 1:length(target_indices)
    figure('Position', [100, 100, 1200, 600]);
    day_idx = target_indices(i);
    current_date = target_dates(i);
    rain_day = squeeze(mjo_data(lat_idx, lon_idx, day_idx));
    rain_day(rain_day <= 0) = NaN;
    [LON, LAT] = meshgrid(lon_target, lat_target);
    contourf(LON, LAT, rain_day, 20, 'LineStyle', 'none');
    colormap(custom_cmap);
    caxis([data_min, data_max]);
    colorbar;
    title(sprintf('MJO Precipitation - %s', datestr(current_date, 'yyyy-mm-dd')), ...
          'FontSize', 14, 'FontWeight', 'bold');
    xlabel('Longitude (°E)', 'FontSize', 12);
    ylabel('Latitude (°N)', 'FontSize', 12);
    xlim(lon_range);
    ylim(lat_range);
    grid on;
    hold on;
    plot(lon_range, [0, 0], 'k--', 'LineWidth', 1); % 赤道
    xticks(80:10:150);
    yticks(-30:10:10);
    set(gca, 'FontSize', 10, 'Box', 'on');
    filename = sprintf('figure_mjo_precip_%s.png', datestr(current_date, 'yyyymmdd'));
    saveas(gcf, filename);
end

fprintf('成功绘制了 %d 张MJO降水填色图\n', length(target_indices));