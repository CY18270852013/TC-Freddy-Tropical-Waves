clear; clc; close all;

%% 文件路径
olr_ncfile = 'E:\Results_of_Freddy_ChenYong_version2\olr_daily\olr_anomaly_for_Kelvin_daily_20220101_20231231.nc';

%% 参数设置
lon_range = [80, 150];
lat_range = [-30, 10];
target_dates = datetime(2023, 2, 1):days(1):datetime(2023, 2, 10);

%% 读取OLR数据
fprintf('正在读取OLR数据...\n');

% 读取维度变量
lon = ncread(olr_ncfile, 'lon');
lat = ncread(olr_ncfile, 'lat');
time = ncread(olr_ncfile, 'time');

% 将时间转换为datetime
time_dates = datetime(1970, 1, 1) + days(time);

% 找到目标区域索引
lon_idx = find(lon >= lon_range(1) & lon <= lon_range(2));
lat_idx = find(lat >= lat_range(1) & lat <= lat_range(2));
lon_sub = lon(lon_idx);
lat_sub = lat(lat_idx);

% 找到目标时间索引
time_indices = [];
for i = 1:length(target_dates)
    idx = find(time_dates == target_dates(i));
    if ~isempty(idx)
        time_indices = [time_indices, idx];
    else
        % 如果精确匹配失败，寻找最接近的日期
        [~, idx] = min(abs(time_dates - target_dates(i)));
        time_indices = [time_indices, idx];
        fprintf('注意：OLR数据中没有精确匹配 %s，使用最接近的日期: %s\n', ...
            datestr(target_dates(i)), datestr(time_dates(idx)));
    end
end

% 检查是否有缺失的时间索引
if length(time_indices) ~= length(target_dates)
    error('未能找到所有目标日期的数据');
end

%% 读取OLR异常数据
% 注意：olr_anomaly_kelvin的维度是 [lat, lon, time]
olr_data = ncread(olr_ncfile, 'olr_anomaly_kelvin');

% 处理缺失值（根据NC文件属性，_FillValue = 0, missing_value = 0）
fill_value = 0;
olr_data(olr_data == fill_value) = NaN;

%% 计算统一颜色范围
fprintf('计算OLR异常颜色范围...\n');
all_olr_data = [];

for i = 1:length(time_indices)
    time_idx = time_indices(i);
    olr_day = squeeze(olr_data(lat_idx, lon_idx, time_idx));
    all_olr_data = [all_olr_data; olr_day(:)];
end

% 移除NaN值
all_olr_data = all_olr_data(~isnan(all_olr_data));

% 计算统一的数据范围（根据实际数据值）
if ~isempty(all_olr_data)
    % 使用2%和98%分位数作为最小值和最大值，减少异常值影响
    data_min = prctile(all_olr_data, 2);
    data_max = prctile(all_olr_data, 98);
    
    % 确保数据范围合理
    if data_min >= 0
        % 如果最小值大于等于0，适当调整以确保负值能被显示
        data_min = min(data_min, -1);
    end
    
    if data_max <= 0
        % 如果最大值小于等于0，适当调整以确保正值能被显示
        data_max = max(data_max, 1);
    end
    
    % 如果数据范围太小，设置一个最小范围
    range_threshold = max(abs([data_min, data_max])) * 0.1;
    if (data_max - data_min) < 10
        data_min = data_min - range_threshold;
        data_max = data_max + range_threshold;
    end
    
    % 四舍五入到最近的5或10
    data_min = floor(data_min/5) * 5;
    data_max = ceil(data_max/5) * 5;
    
else
    % 如果没有有效数据，使用默认范围
    data_min = -30;
    data_max = 30;
end

fprintf('统一OLR颜色轴范围: %.4f 到 %.4f W/m²\n', data_min, data_max);

%% 创建自定义颜色映射（蓝色-白色-红色，用于显示正负异常）
num_colors = 64;  % 更多的颜色级别以获得平滑过渡

% 定义关键颜色点
% 蓝色系（负异常，对流活跃）
blue_colors = [
    0.0, 0.0, 0.8;   % 深蓝色
    0.2, 0.4, 1.0;   % 蓝色
    0.6, 0.8, 1.0;   % 浅蓝色
];

% 白色（零值附近）
white_color = [1.0, 1.0, 1.0];  % 纯白色

% 红色系（正异常，对流抑制）
red_colors = [
    1.0, 0.8, 0.6;   % 浅红色
    1.0, 0.4, 0.2;   % 红色
    0.8, 0.0, 0.0;   % 深红色
];

% 组合所有关键颜色
key_colors = [blue_colors; white_color; red_colors];

% 对每个颜色通道进行线性插值
x = linspace(1, size(key_colors, 1), size(key_colors, 1));
xi = linspace(1, size(key_colors, 1), num_colors);
custom_cmap = zeros(num_colors, 3);
for channel = 1:3
    custom_cmap(:, channel) = interp1(x, key_colors(:, channel), xi, 'linear');
end
custom_cmap = max(0, min(1, custom_cmap));

%% 绘制OLR异常图
fprintf('开始绘制OLR异常图...\n');

for i = 1:length(target_dates)
    current_date = target_dates(i);
    fprintf('正在绘制 %s 的OLR异常图...\n', datestr(current_date, 'yyyy-mm-dd'));
    
    % 创建新图形
    figure('Position', [100, 100, 1200, 600]);
    
    % 获取当前日期的OLR异常数据
    time_idx = time_indices(i);
    olr_day = squeeze(olr_data(lat_idx, lon_idx, time_idx));
    
    % 创建经纬度网格
    [LON, LAT] = meshgrid(lon_sub, lat_sub);
    
    % 绘制填色图
    contourf(LON, LAT, olr_day, 30, 'LineStyle', 'none');
    hold on;
    
    % 设置颜色映射和范围
    colormap(custom_cmap);
    caxis([data_min, data_max]);
    
    % ========== 图形设置 ==========
    % 坐标轴标签
    xlabel('Longitude (°E)', 'FontSize', 12);
    ylabel('Latitude (°N)', 'FontSize', 12);
    
    % 标题
    title(sprintf('Kelvin-filtered OLR Anomaly\n%s', ...
        datestr(current_date, 'dd-mmm-yyyy')), 'FontSize', 14, 'FontWeight', 'bold');
    
    % 坐标轴范围
    xlim(lon_range);
    ylim(lat_range);
    
    % 网格和刻度
    grid on;
    xticks(80:10:150);
    yticks(-30:5:10);
    
    % ========== 添加颜色条 ==========
    cbar = colorbar;
    ylabel(cbar, 'OLR Anomaly (W m^{-2})', 'FontSize', 11);
    
    % 在颜色条上标记零值
    cbar_ticks = get(cbar, 'Ticks');
    if ~ismember(0, cbar_ticks)
        cbar_ticks = sort([cbar_ticks, 0]);
        set(cbar, 'Ticks', cbar_ticks);
    end
    
    % ========== 添加海岸线和赤道线 ==========
    % 加载海岸线数据
    load coastlines;
    
    % 绘制海岸线
    plot(coastlon, coastlat, 'k', 'LineWidth', 1.0);
    
    % 绘制赤道线
    plot(lon_range, [0, 0], 'k--', 'LineWidth', 1.2, 'Color', [0.3, 0.3, 0.3]);
    
    % 添加零值等值线（可选）
    contour(LON, LAT, olr_day, [0, 0], 'k-', 'LineWidth', 0.8);
    
    hold off;
    
    % 设置图形背景为白色
    set(gcf, 'Color', 'w');
    set(gca, 'FontSize', 11);
    
    % ========== 保存图形 ==========
    % 创建保存目录（如果不存在）
    save_dir = 'OLR_anomaly_plots';
    if ~exist(save_dir, 'dir')
        mkdir(save_dir);
    end
    
    filename = fullfile(save_dir, sprintf('OLR_anomaly_Kelvin_%s.png', ...
        datestr(current_date, 'yyyymmdd')));
    saveas(gcf, filename, 'png');
    
    % 也可以保存为更高分辨率的图片
    % print(gcf, filename, '-dpng', '-r300');
    
    fprintf('已保存: %s\n', filename);
    
    % 关闭图形以节省内存（可选）
    close(gcf);
end

%% 绘制示例图（只绘制第一天的图并显示）
if ~isempty(target_dates)
    fprintf('绘制示例图并显示...\n');
    
    % 绘制第一天的图
    current_date = target_dates(1);
    time_idx = time_indices(1);
    olr_day = squeeze(olr_data(lat_idx, lon_idx, time_idx));
    
    figure('Position', [100, 100, 1200, 600]);
    
    % 创建经纬度网格
    [LON, LAT] = meshgrid(lon_sub, lat_sub);
    
    % 绘制填色图
    h = contourf(LON, LAT, olr_day, 30, 'LineStyle', 'none');
    hold on;
    
    % 设置颜色映射和范围
    colormap(custom_cmap);
    caxis([data_min, data_max]);
    
    % 添加海岸线
    plot(coastlon, coastlat, 'k', 'LineWidth', 1.2);
    
    % 添加赤道线
    plot(lon_range, [0, 0], 'k--', 'LineWidth', 1.5, 'Color', [0.3, 0.3, 0.3]);
    
    % 添加零值等值线
    contour(LON, LAT, olr_day, [0, 0], 'k-', 'LineWidth', 1.2);
    
    % 坐标轴设置
    xlabel('Longitude (°E)', 'FontSize', 13);
    ylabel('Latitude (°N)', 'FontSize', 13);
    title(sprintf('Kelvin-filtered Daily OLR Anomaly\n%s', ...
        datestr(current_date, 'dd-mmm-yyyy')), 'FontSize', 15, 'FontWeight', 'bold');
    
    xlim(lon_range);
    ylim(lat_range);
    grid on;
    xticks(80:10:150);
    yticks(-30:5:10);
    
    % 添加颜色条
    cbar = colorbar;
    ylabel(cbar, 'OLR Anomaly (W m^{-2})', 'FontSize', 12);
    
    % 标记零值
    cbar_ticks = get(cbar, 'Ticks');
    if ~ismember(0, cbar_ticks)
        cbar_ticks = sort([cbar_ticks, 0]);
        set(cbar, 'Ticks', cbar_ticks);
    end
    
    % 设置图形外观
    set(gcf, 'Color', 'w');
    set(gca, 'FontSize', 12, 'LineWidth', 1.2);
    
    hold off;
    
    fprintf('示例图绘制完成。\n');
end

fprintf('所有OLR异常图片绘制完成！\n');