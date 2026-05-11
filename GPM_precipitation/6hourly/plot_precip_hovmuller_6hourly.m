clear; close all; clc;
data_path = 'E:\Results_of_Freddy\GPM_anomaly_6hourly\';

%% 读取数据
disp('读取原始降水异常数据...');
nc_file1 = fullfile(data_path, 'GPM_anomaly_6hourly_20220901_20230630.nc');
precip_anomaly = ncread(nc_file1, 'precipitation_anomaly'); % 400x3600x1212 (lat, lon, time)
lon = ncread(nc_file1, 'lon');
lat = ncread(nc_file1, 'lat');
time1 = ncread(nc_file1, 'time');

% 显示时间信息
disp(['时间变量大小: ', num2str(length(time1))]);

% 创建时间向量 - 基于文件的时间变量
% 从时间覆盖范围属性推断时间
time_coverage_start = '2022-09-01 00:00:00';
time_coverage_end = '2023-06-30 18:00:00';

% 创建6小时间隔的时间序列
num_times = 1212;
start_date = datetime(time_coverage_start, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
end_date = datetime(time_coverage_end, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
time_vec = start_date:hours(6):end_date;

% 确保时间点数量匹配
if length(time_vec) ~= num_times
    disp('警告: 生成的时间序列长度与数据时间维度不匹配!');
    % 使用实际时间维度
    time_vec = start_date:hours(6):(start_date + hours(6*(num_times-1)));
end

disp(['时间向量范围: ', datestr(time_vec(1)), ' 到 ', datestr(time_vec(end))]);
disp(['总时间点数: ', num2str(length(time_vec))]);

% 读取滤波数据
disp('读取MJO滤波数据...');
nc_file2 = fullfile(data_path, 'GPM_anomaly_6hourly_for_MJO_20220901_20230630.nc');
mjo_precip = ncread(nc_file2, 'precipitation_anomaly_mjo'); % 400x3600x1212 (lat, lon, time)

disp('读取Kelvin波滤波数据...');
nc_file3 = fullfile(data_path, 'GPM_anomaly_6hourly_for_Kelvin_20220901_20230630.nc');
kelvin_precip = ncread(nc_file3, 'precipitation_anomaly_kelvin');

disp('读取MRG波滤波数据...');
nc_file4 = fullfile(data_path, 'GPM_anomaly_6hourly_for_MRG_20220901_20230630.nc');
mrg_precip = ncread(nc_file4, 'precipitation_anomaly_mrg');

disp('读取ER波滤波数据...');
nc_file5 = fullfile(data_path, 'GPM_anomaly_6hourly_for_ER_20220901_20230630.nc');
er_precip = ncread(nc_file5, 'precipitation_anomaly_er');

%% 定义研究区域
lon_min = 80;
lon_max = 180;
lon_idx = find(lon >= lon_min & lon <= lon_max);

lat_min = -20;
lat_max = -10;
lat_idx = find(lat >= lat_min & lat <= lat_max);

start_time = datetime(2023, 1, 1, 0, 0, 0);
end_time = datetime(2023, 3, 31, 23, 59, 59);
time_idx = find(time_vec >= start_time & time_vec <= end_time);

disp(['在指定时间范围内找到的时间点数量: ', num2str(length(time_idx))]);

%% 提取研究区域数据
disp('提取研究区域数据...');
lon_region = lon(lon_idx);
lat_region = lat(lat_idx);
time_region = time_vec(time_idx);

disp(['经度点数: ', num2str(length(lon_region))]);
disp(['纬度点数: ', num2str(length(lat_region))]);
disp(['时间点数: ', num2str(length(time_region))]);
disp(['数据时间范围: ', datestr(time_region(1)), ' 到 ', datestr(time_region(end))]);

% 提取数据
precip_region = precip_anomaly(lat_idx, lon_idx, time_idx);
mjo_region = mjo_precip(lat_idx, lon_idx, time_idx);
kelvin_region = kelvin_precip(lat_idx, lon_idx, time_idx);
mrg_region = mrg_precip(lat_idx, lon_idx, time_idx);
er_region = er_precip(lat_idx, lon_idx, time_idx);

%% 沿纬度方向平均
disp('沿纬度方向平均...');
precip_avg = squeeze(mean(precip_region, 1, 'omitnan'));
mjo_avg = squeeze(mean(mjo_region, 1, 'omitnan'));
kelvin_avg = squeeze(mean(kelvin_region, 1, 'omitnan'));
mrg_avg = squeeze(mean(mrg_region, 1, 'omitnan'));
er_avg = squeeze(mean(er_region, 1, 'omitnan'));

% 转置数据维度（时间点数 x 经度点数）
if size(precip_avg, 1) == length(lon_region)
    precip_avg = precip_avg';
    mjo_avg = mjo_avg';
    kelvin_avg = kelvin_avg';
    mrg_avg = mrg_avg';
    er_avg = er_avg';
    disp('已转置数据维度');
end

disp(['调整后precip_avg维度: ', num2str(size(precip_avg))]);

%% 检查滤波数据振幅
disp('=== 滤波数据振幅检查 ===');
precip_min = min(precip_avg(:), [], 'omitnan');
precip_max = max(precip_avg(:), [], 'omitnan');
disp(['precipitation_anomaly数据范围: ', num2str(precip_min), ' 到 ', num2str(precip_max)]);

mjo_min = min(mjo_avg(:), [], 'omitnan');
mjo_max = max(mjo_avg(:), [], 'omitnan');
disp(['MJO滤波数据范围: ', num2str(mjo_min), ' 到 ', num2str(mjo_max)]);

kelvin_min = min(kelvin_avg(:), [], 'omitnan');
kelvin_max = max(kelvin_avg(:), [], 'omitnan');
disp(['Kelvin滤波数据范围: ', num2str(kelvin_min), ' 到 ', num2str(kelvin_max)]);

mrg_min = min(mrg_avg(:), [], 'omitnan');
mrg_max = max(mrg_avg(:), [], 'omitnan');
disp(['MRG滤波数据范围: ', num2str(mrg_min), ' 到 ', num2str(mrg_max)]);

er_min = min(er_avg(:), [], 'omitnan');
er_max = max(er_avg(:), [], 'omitnan');
disp(['ER滤波数据范围: ', num2str(er_min), ' 到 ', num2str(er_max)]);
disp('======================');

%% 根据数据范围调整绘图参数
% 根据滤波数据范围设置等值线
contour_levels = [0.5, 1, 1.5, 2];
disp(['使用等值线级别: ', num2str(contour_levels)]);

%% 准备绘图数据
lon_region_numeric = double(lon_region);
time_region_numeric = datenum(time_region);
[X, T] = meshgrid(lon_region_numeric, time_region_numeric);

%% Freddy生成信息
freddy_gen_time = datetime(2023, 2, 6, 0, 0, 0);
freddy_gen_time_num = datenum(freddy_gen_time);
freddy_gen_lon_min = 110;
freddy_gen_lon_max = 120;
freddy_time_min = freddy_gen_time_num - 1;
freddy_time_max = freddy_gen_time_num + 1;

%% 创建图形
disp('创建图形...');
figure('Position', [100, 100, 800, 800]);

%% 绘制降水异常填色图
subplot('Position', [0.12, 0.01, 0.75, 0.9]);
hold on;

% 使用imagesc代替pcolor，提高性能
h = imagesc(lon_region_numeric, time_region_numeric, precip_avg);
set(gca, 'YDir', 'normal'); % 确保时间正向

% 创建更好的颜色映射 - 根据要求修改：小于0的值由浅蓝到白色，0值附近很窄一段用白色，大于0的区域由浅红到深红色
ncolors = 64;

% 设置负值部分的比例（浅蓝到白色）
neg_ratio = 0.13;  % 负值部分占13%
% 设置正值部分的比例（白色到深红）
pos_ratio = 0.86;  % 正值部分占86%
% 设置0值附近白色区域的比例（很窄一段）
white_ratio = 0.01;  % 白色区域占1%

% 计算各部分的颜色数量
neg_colors = round(neg_ratio * ncolors);
white_colors = round(white_ratio * ncolors);
pos_colors = ncolors - neg_colors - white_colors;

% 定义颜色端点
% 负值部分：从浅蓝到白色
neg_start = [0.7, 0.85, 1];   % 浅蓝色
neg_end = [1, 1, 1];          % 白色

% 正值部分：从白色到深红色
pos_start = [1, 1, 1];        % 白色
pos_end = [1.0, 0.4, 0.0];    % 深红色

% 生成颜色映射
cmap = zeros(ncolors, 3);

% 生成负值部分颜色（浅蓝到白色）
if neg_colors > 1
    for i = 1:neg_colors
        ratio = (i-1)/(neg_colors-1);
        cmap(i,:) = (1-ratio)*neg_start + ratio*neg_end;
    end
elseif neg_colors == 1
    cmap(1,:) = neg_start;
end

% 生成白色部分颜色
for i = 1:white_colors
    cmap(neg_colors + i,:) = [1, 1, 1];
end

% 生成正值部分颜色（白色到深红）
if pos_colors > 1
    for i = 1:pos_colors
        ratio = (i-1)/(pos_colors-1);
        cmap(neg_colors + white_colors + i,:) = (1-ratio)*pos_start + ratio*pos_end;
    end
elseif pos_colors == 1
    cmap(neg_colors + white_colors + 1,:) = pos_start;
end

colormap(cmap);

% 设置填色范围
precip_sorted = sort(precip_avg(:));
valid_idx = ~isnan(precip_sorted);
if sum(valid_idx) > 0
    precip_sorted = precip_sorted(valid_idx);
    lower_bound = precip_sorted(max(1, floor(0.02*length(precip_sorted)))); % 2%分位数
    upper_bound = precip_sorted(min(length(precip_sorted), ceil(0.98*length(precip_sorted)))); % 98%分位数
    
    % 直接使用计算的分位数作为填色范围
    precip_range = [lower_bound, upper_bound];
    
    caxis(precip_range);
    disp(['填色范围(2%~98%分位数): ', num2str(precip_range)]);
else
    caxis([-5, 10]);
end

% 添加颜色条
cb = colorbar('Position', [0.9, 0.12, 0.03, 0.78]);
cb.Label.String = 'Precipitation Anomaly (mm)';
cb.Label.FontSize = 12;

%% 绘制各波列的等值线
% 检查并绘制等值线
legend_handles = [];
legend_labels = {};
line_colors = {'black', 'blue', [0, 0.6, 0], 'red'};
line_styles = {'-', '-', '-', '-'};
line_widths = [1.6, 1.6, 1.6, 1.6];
data_sets = {mjo_avg, kelvin_avg, mrg_avg, er_avg};
data_names = {'MJO', 'Kelvin Waves', 'Mixed Rossby-Gravity Waves', 'Equatorial Rossby Waves'};

for i = 1:4
    data = data_sets{i};
    if ~all(isnan(data(:)))
        % 创建特定于每种波的等值线
        % 只绘制正值等值线
        pos_contour_levels = contour_levels(contour_levels > 0);
        
        if ~isempty(pos_contour_levels)
            [~, h_contour] = contour(X, T, data, pos_contour_levels, ...
                'LineColor', line_colors{i}, ...
                'LineWidth', line_widths(i), ...
                'LineStyle', line_styles{i}, ...
                'ShowText', 'off');
            legend_handles = [legend_handles, h_contour];
            legend_labels = [legend_labels, data_names{i}];
        end
    else
        disp([data_names{i}, ' 数据全为NaN，跳过绘制']);
    end
end

%% 标记Freddy热带气旋生成位置
rectangle('Position', [freddy_gen_lon_min, freddy_time_min, ...
    freddy_gen_lon_max - freddy_gen_lon_min, ...
    freddy_time_max - freddy_time_min], ...
    'EdgeColor', 'magenta', 'LineWidth', 2.5, 'LineStyle', '-');

% text(freddy_gen_lon_min + 2.5, freddy_gen_time_num, 'Freddy', ...
%     'Color', 'magenta', 'FontSize', 14, 'FontWeight', 'bold', ...
%     'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
%     'BackgroundColor', 'white');

%% 设置图形属性
xlim([lon_min, lon_max]);
ylim([min(time_region_numeric), max(time_region_numeric)]);

xlabel('Longitude (°E)', 'FontSize', 14, 'FontWeight', 'bold');
xticks(80:20:180);
xticklabels({'80°E', '100°E', '120°E', '140°E', '160°E', '180°E'});

ylabel('Date (2023)', 'FontSize', 14, 'FontWeight', 'bold');

% 设置时间刻度
date_ticks = datenum(start_time:7:end_time); % 每周一个刻度
yticks(date_ticks);
datetick('y', 'mm/dd', 'keepticks');

% 旋转时间标签，使其更易读
ax = gca;
ax.TickLabelInterpreter = 'none';

% 设置标题
title_str = sprintf('Time-Longitude Hovmöller Diagram\nPrecipitation Anomaly (10°S-20°S) for Tropical Cyclone Freddy\n%s to %s', ...
    datestr(time_region(1), 'dd-mmm'), datestr(time_region(end), 'dd-mmm'));
title(title_str, 'FontSize', 15, 'FontWeight', 'bold');

% 添加图例
if ~isempty(legend_handles)
    legend(legend_handles, legend_labels, ...
        'Location', 'southoutside', 'FontSize', 10, 'Box', 'on', 'Orientation','horizontal');
end

grid on;
box on;
set(gca, 'GridLineStyle', ':', 'GridAlpha', 0.3, 'Layer', 'top');

% 调整图形外观
set(gca, 'FontSize', 12, 'FontWeight', 'normal');
set(gcf, 'Color', 'white');

% 保存图形
output_path = 'D:\Freddy_ChenYong\Codes_Matlab\process_GPM_precipitation_data_6hourly\';
if ~exist(output_path, 'dir')
    mkdir(output_path);
end

output_file = fullfile(output_path, 'Freddy_Hovmoller_Diagram.png');
print(output_file, '-dpng', '-r300');
disp(['图形已保存至: ', output_file]);

%% 显示信息
disp('===============================================');
disp('数据信息：');
disp(['纬度范围: ', num2str(abs(lat_max)), '°S 到 ', num2str(abs(lat_min)), '°S']);
disp(['经度范围: ', num2str(lon_min), '°E 到 ', num2str(lon_max), '°E']);
disp(['时间范围: ', datestr(time_region(1)), ' 到 ', datestr(time_region(end))]);
disp(['Freddy生成时间: ', datestr(freddy_gen_time)]);
disp(['Freddy生成经度范围: ', num2str(freddy_gen_lon_min), '°E 到 ', ...
    num2str(freddy_gen_lon_max), '°E']);
disp(['数据维度: ', num2str(size(precip_avg, 1)), ' 个时间点 × ', ...
    num2str(size(precip_avg, 2)), ' 个经度点']);
disp(['等值线级别: ', num2str(contour_levels(1)), ':', ...
    num2str(contour_levels(2)-contour_levels(1)), ':', ...
    num2str(contour_levels(end)), ' mm']);
disp('===============================================');