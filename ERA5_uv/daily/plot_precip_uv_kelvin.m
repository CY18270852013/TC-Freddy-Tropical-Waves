clear; clc; close all;

%% 文件路径
wind_ncfile = 'E:\Results_of_Freddy_ChenYong_version2\u_v_daily\u_v_anomaly_for_Kelvin_daily_20220101_20231231.nc';
precip_ncfile = 'E:\Results_of_Freddy_ChenYong_version2\GPM_anomaly_daily\GPM_anomaly_for_Kelvin_daily_20220901_20230630.nc';

%% 参数设置
lon_range = [80, 150];
lat_range = [-30, 10];
target_dates = datetime(2023, 2, 1):days(1):datetime(2023, 2, 10);
ref_wind_speed = 4.0;  % 最长矢量对应4 m/s
wind_skip = 5;         % 风场稀疏化因子

%% 读取风场数据
fprintf('正在读取风场数据...\n');
lon_wind = ncread(wind_ncfile, 'lon');
lat_wind = ncread(wind_ncfile, 'lat');
time_wind = ncread(wind_ncfile, 'time');

% 将时间转换为datetime
time_dates_wind = datetime(time_wind, 'ConvertFrom', 'datenum', 'Format', 'yyyy-MM-dd');

% 找到目标区域索引
lon_idx_wind = find(lon_wind >= lon_range(1) & lon_wind <= lon_range(2));
lat_idx_wind = find(lat_wind >= lat_range(1) & lat_wind <= lat_range(2));
lon_sub_wind = lon_wind(lon_idx_wind);
lat_sub_wind = lat_wind(lat_idx_wind);

% 找到目标时间索引
time_indices_wind = [];
for i = 1:length(target_dates)
    idx = find(time_dates_wind == target_dates(i));
    if ~isempty(idx)
        time_indices_wind = [time_indices_wind, idx];
    else
        % 如果精确匹配失败，寻找最接近的日期
        [~, idx] = min(abs(time_dates_wind - target_dates(i)));
        time_indices_wind = [time_indices_wind, idx];
        fprintf('注意：风场数据中没有精确匹配 %s，使用最接近的日期: %s\n', ...
            datestr(target_dates(i)), datestr(time_dates_wind(idx)));
    end
end

%% 读取降水数据
fprintf('正在读取降水数据...\n');
time_precip = ncread(precip_ncfile, 'time');
lat_precip = ncread(precip_ncfile, 'lat');
lon_precip = ncread(precip_ncfile, 'lon');
kelvin_data = ncread(precip_ncfile, 'kelvin');

% 注意：kelvin_data的维度是 [经度, 纬度, 时间]
% 需要转换为 [纬度, 经度, 时间] 以便绘图
kelvin_data = permute(kelvin_data, [2, 1, 3]);  % 现在维度是: lat x lon x time

% 处理缺失值
fill_value = -9999.9004;
kelvin_data(kelvin_data == fill_value) = NaN;

% 找到目标区域索引
lat_idx_precip = find(lat_precip >= lat_range(1) & lat_precip <= lat_range(2));
lon_idx_precip = find(lon_precip >= lon_range(1) & lon_precip <= lon_range(2));
lat_target_precip = lat_precip(lat_idx_precip);
lon_target_precip = lon_precip(lon_idx_precip);

% 生成降水时间序列
nc_start_date = datetime('20220901', 'InputFormat', 'yyyyMMdd');  % 2022-09-01
full_dates_precip = nc_start_date + days(0:302);  % 2022-09-01 到 2023-06-30

% 找到目标日期索引
[~, time_indices_precip] = ismember(target_dates, full_dates_precip);

% 检查是否有缺失的日期
missing_dates = find(time_indices_precip == 0);
if ~isempty(missing_dates)
    for i = 1:length(missing_dates)
        [~, time_indices_precip(missing_dates(i))] = ...
            min(abs(full_dates_precip - target_dates(missing_dates(i))));
        fprintf('注意：降水数据中没有精确匹配 %s，使用最接近的日期: %s\n', ...
            datestr(target_dates(missing_dates(i))), ...
            datestr(full_dates_precip(time_indices_precip(missing_dates(i)))));
    end
end

%% 计算风场统一比例尺
fprintf('计算风场缩放因子...\n');
max_wind_speed = 0;

% 预先读取所有需要的风场数据
u_data_all = cell(length(time_indices_wind), 1);
v_data_all = cell(length(time_indices_wind), 1);

for i = 1:length(time_indices_wind)
    time_idx = time_indices_wind(i);
    
    % 读取u、v异常场
    % 注意维度顺序: [lon, lat, time]
    start = [min(lon_idx_wind), min(lat_idx_wind), time_idx];
    count = [length(lon_idx_wind), length(lat_idx_wind), 1];
    
    u_anom = ncread(wind_ncfile, 'u_anomaly_kelvin', start, count);
    v_anom = ncread(wind_ncfile, 'v_anomaly_kelvin', start, count);
    
    % 转置以匹配绘图需求 (lat x lon)
    u_anom = u_anom';
    v_anom = v_anom';
    
    u_data_all{i} = u_anom;
    v_data_all{i} = v_anom;
    
    % 计算风速
    wind_speed = sqrt(u_anom.^2 + v_anom.^2);
    current_max = max(wind_speed(:));
    if current_max > max_wind_speed
        max_wind_speed = current_max;
    end
end

% 计算缩放因子
scale_factor = ref_wind_speed / max_wind_speed;
fprintf('最大风速: %.2f m/s, 参考风速: %.2f m/s, 缩放因子: %.4f\n', ...
    max_wind_speed, ref_wind_speed, scale_factor);

%% 计算降水统一颜色范围
fprintf('计算降水颜色范围...\n');
all_precip_data = [];

for i = 1:length(time_indices_precip)
    day_idx = time_indices_precip(i);
    rain_day = squeeze(kelvin_data(lat_idx_precip, lon_idx_precip, day_idx));
    
    % 只考虑正值，与论文要求一致
    positive_vals = rain_day(rain_day > 0);
    all_precip_data = [all_precip_data; positive_vals(:)];
end

% 计算统一的数据范围
if ~isempty(all_precip_data)
    data_min = 0;
    % 使用98%分位数作为最大值，减少极值影响
    data_max = prctile(all_precip_data, 98);
    % 确保最大值至少为1
    data_max = max(data_max, 1);
else
    data_min = 0;
    data_max = 5;  % 默认值
end

% 与论文中的图3a保持一致，这里可以适当调整
% data_max = min(data_max, 20);  % 设置上限为20mm
data_max = 10;
fprintf('统一降水颜色轴范围: %.4f 到 %.4f mm\n', data_min, data_max);

%% 创建自定义颜色映射
num_colors = 10;
key_colors = [
    1.0, 1.0, 1.0;   % （无降水，纯白色）
    0.9, 0.95, 1.0;  % （浅淡蓝）
    0.7, 0.85, 1.0;  % （淡蓝）
    0.5, 0.75, 1.0;  % （天蓝）
    0.3, 0.9, 0.9;   % （青蓝）
    0.2, 0.8, 0.6;   % （浅绿）
    0.4, 0.9, 0.3;   % （鲜绿）
    0.8, 0.9, 0.2;   % （亮黄）
    1.0, 0.8, 0.0;   % （橙黄）
    1.0, 0.5, 0.0;   %（橙红）
    1.0, 0.2, 0.0;   % （深红）
    0.8, 0.0, 0.2;   % （暗紫红）
];

% 对每个颜色通道进行线性插值
x = linspace(1, size(key_colors, 1), size(key_colors, 1));
xi = linspace(1, size(key_colors, 1), num_colors + 1);
custom_cmap = zeros(num_colors + 1, 3);
for channel = 1:3
    custom_cmap(:, channel) = interp1(x, key_colors(:, channel), xi, 'linear');
end
custom_cmap = max(0, min(1, custom_cmap));

%% 绘制合成图
fprintf('开始绘制合成图...\n');

for i = 1:length(target_dates)
    current_date = target_dates(i);
    fprintf('正在绘制 %s 的合成图...\n', datestr(current_date, 'yyyy-mm-dd'));
    
    % 创建新图形
    figure('Position', [100, 100, 1200, 600]);
    
    % ========== 绘制降水异常 ==========
    precip_idx = time_indices_precip(i);
    rain_day = squeeze(kelvin_data(lat_idx_precip, lon_idx_precip, precip_idx));
    
    % 只保留正值，与论文要求一致
    rain_day(rain_day <= 0) = NaN;
    
    % 创建经纬度网格
    [LON_precip, LAT_precip] = meshgrid(lon_target_precip, lat_target_precip);
    
    % 绘制填色图
    contourf(LON_precip, LAT_precip, rain_day, 20, 'LineStyle', 'none');
    hold on;
    
    % 设置颜色映射和范围
    colormap(custom_cmap);
    caxis([data_min, data_max]);
    
    % ========== 绘制风场异常 ==========
    % 获取当前日期的风场数据
    u_anom = u_data_all{i};
    v_anom = v_data_all{i};
    
    % 创建风场的经纬度网格
    [LON_wind, LAT_wind] = meshgrid(lon_sub_wind, lat_sub_wind);
    
    % 稀疏化风场（避免过于密集）
    skip = wind_skip;
    
    % 缩放风矢量
    u_scaled = u_anom * scale_factor;
    v_scaled = v_anom * scale_factor;
    
    % 绘制风矢量
    quiver(LON_wind(1:skip:end, 1:skip:end), LAT_wind(1:skip:end, 1:skip:end), ...
           u_scaled(1:skip:end, 1:skip:end), v_scaled(1:skip:end, 1:skip:end), ...
           0, 'k', 'LineWidth', 0.8, 'AutoScale', 'off');
    
    % ========== 图形设置 ==========
    % 坐标轴标签
    xlabel('Longitude (°E)', 'FontSize', 12);
    ylabel('Latitude (°N)', 'FontSize', 12);
    
    % 标题
    title(sprintf('Kelvin-filtered 850 hPa Wind Anomalies & Precipitation Anomalies\n%s', ...
        datestr(current_date, 'dd-mmm-yyyy')), 'FontSize', 14, 'FontWeight', 'bold');
    
    % 坐标轴范围
    xlim(lon_range);
    ylim(lat_range);
    
    % 网格和刻度
    grid on;
    xticks(80:10:150);
    yticks(-30:10:10);
    
    % ========== 添加参考矢量 ==========
    ref_x = lon_range(2) - 6;
    ref_y = lat_range(2) + 3;
    
    % 绘制参考箭头
    quiver(ref_x, ref_y, ref_wind_speed, 0, 0, 'k', 'LineWidth', 2, ...
           'AutoScale', 'off', 'MaxHeadSize', 0.5, 'Clipping', 'off');
    
    % 添加参考文本
    text(ref_x, ref_y - 1, sprintf('%.1f m s^{-1}', ref_wind_speed), ...
         'Color', 'k', 'FontSize', 10, 'FontWeight', 'bold');
    
    % ========== 添加颜色条 ==========
    cbar = colorbar;
    ylabel(cbar, 'Precipitation Anomaly (mm)', 'FontSize', 11);
    
    % ========== 添加海岸线和赤道线 ==========
    % 加载海岸线数据
    load coastlines;
    
    % 绘制海岸线
    plot(coastlon, coastlat, 'k', 'LineWidth', 0.8);
    
    % 绘制赤道线
    plot(lon_range, [0, 0], 'k--', 'LineWidth', 1, 'Color', [0.5, 0.5, 0.5]);
    
    hold off;
    
    % ========== 保存图形 ==========
    filename = sprintf('Kelvin_precip_wind_anomalies_%s.png', ...
        datestr(current_date, 'yyyymmdd'));
    saveas(gcf, filename, 'png');
    
    % 也可以保存为更高质量的图片
    % print(gcf, filename, '-dpng', '-r300');
    
    fprintf('已保存: %s\n', filename);
    
    % 关闭图形以节省内存（可选）
    close(gcf);
end

fprintf('所有合成图片绘制完成！\n');