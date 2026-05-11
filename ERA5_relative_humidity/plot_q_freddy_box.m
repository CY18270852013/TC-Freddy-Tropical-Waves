%% 绘制Freddy生成区域相对湿度变化图 - 仿照文献Fig.8(a)
% 作者: ChatGPT
% 日期: 2024
% 描述: 处理ERA5相对湿度数据，绘制Freddy生成区域在500hPa、700hPa、850hPa的相对湿度变化

clear; clc; close all;

%% 1. 设置参数
% 文件路径
file_path = 'E:\Original_Data_of_Freddy_ChenYong\ERA5_dv_q_uv_200901_202312_every_6hours\';
file_names = {'202301_q.nc', '202302_q.nc', '202303_q.nc'};

% 研究区域
lon_range = [110, 120];   % 经度范围: 110-120°E
lat_range = [-20, -10];   % 纬度范围: 10-20°S

% 气压层 (单位: hPa)
pressure_levels = [500, 700, 850];  % 需要提取的气压层
pressure_names = {'500 hPa', '700 hPa', '850 hPa'};
pressure_colors = {'b', 'r', 'g'};  % 颜色: 蓝色、红色、绿色

% 时间范围
start_date = datetime(2023, 2, 1);
end_date = datetime(2023, 3, 15);

% 相对湿度阈值线
rh_threshold = 81;  % 81%相对湿度线

%% 2. 初始化变量
% 获取第一个文件的维度信息，用于预分配数组
first_file = [file_path, file_names{1}];
lon = ncread(first_file, 'longitude');
lat = ncread(first_file, 'latitude');
pres = ncread(first_file, 'pressure_level');
time_all = [];

% 计算总时间点数（预分配）
total_times = 0;
for i = 1:length(file_names)
    file = [file_path, file_names{i}];
    time_data = ncread(file, 'valid_time');
    total_times = total_times + length(time_data);
end

% 预分配数组
rh_data_500 = zeros(total_times, 1);
rh_data_700 = zeros(total_times, 1);
rh_data_850 = zeros(total_times, 1);
time_dates = NaT(total_times, 1);  % 预分配datetime数组

%% 3. 处理数据
data_index = 1;
for file_idx = 1:length(file_names)
    fprintf('处理文件: %s...\n', file_names{file_idx});
    
    % 读取数据
    file = [file_path, file_names{file_idx}];
    
    % 读取时间和相对湿度
    time_seconds = ncread(file, 'valid_time');  % 秒数 since 1970-01-01
    rh_all = ncread(file, 'r');  % 相对湿度变量
    
    % 转换时间为datetime
    time_dates_file = datetime(1970, 1, 1) + seconds(double(time_seconds));
    
    % 获取区域索引
    lon_idx = find(lon >= lon_range(1) & lon <= lon_range(2));
    lat_idx = find(lat >= lat_range(1) & lat <= lat_range(2));
    
    % 获取气压层索引
    pres_idx_500 = find(pres == pressure_levels(1));
    pres_idx_700 = find(pres == pressure_levels(2));
    pres_idx_850 = find(pres == pressure_levels(3));
    
    if isempty(pres_idx_500) || isempty(pres_idx_700) || isempty(pres_idx_850)
        error('未找到指定的气压层数据！');
    end
    
    % 提取区域平均相对湿度
    for t = 1:length(time_seconds)
        % 提取当前时间点的数据
        rh_slice_500 = rh_all(lon_idx, lat_idx, pres_idx_500, t);
        rh_slice_700 = rh_all(lon_idx, lat_idx, pres_idx_700, t);
        rh_slice_850 = rh_all(lon_idx, lat_idx, pres_idx_850, t);
        
        % 计算区域平均值（忽略NaN值）
        rh_data_500(data_index) = mean(rh_slice_500(:), 'omitnan');
        rh_data_700(data_index) = mean(rh_slice_700(:), 'omitnan');
        rh_data_850(data_index) = mean(rh_slice_850(:), 'omitnan');
        
        % 保存时间
        time_dates(data_index) = time_dates_file(t);
        
        data_index = data_index + 1;
    end
end

% 截断预分配的数组（如果有空余）
rh_data_500 = rh_data_500(1:data_index-1);
rh_data_700 = rh_data_700(1:data_index-1);
rh_data_850 = rh_data_850(1:data_index-1);
time_dates = time_dates(1:data_index-1);

% 筛选时间范围
time_mask = time_dates >= start_date & time_dates <= end_date;
time_dates_filtered = time_dates(time_mask);
rh_500_filtered = rh_data_500(time_mask);
rh_700_filtered = rh_data_700(time_mask);
rh_850_filtered = rh_data_850(time_mask);

%% 4. 绘制图形
figure('Position', [100, 100, 1200, 600]);

% 绘制三条折线
hold on;
plot(time_dates_filtered, rh_500_filtered, 'Color', pressure_colors{1}, ...
    'LineWidth', 2, 'DisplayName', pressure_names{1});
plot(time_dates_filtered, rh_700_filtered, 'Color', pressure_colors{2}, ...
    'LineWidth', 2, 'DisplayName', pressure_names{2});
plot(time_dates_filtered, rh_850_filtered, 'Color', pressure_colors{3}, ...
    'LineWidth', 2, 'DisplayName', pressure_names{3});

% 添加81%相对湿度水平线
yline(rh_threshold, '--', 'Color', [1, 0.5, 0], 'LineWidth', 2, ...
    'DisplayName', sprintf('%d%% RH', rh_threshold));

% 设置图形属性
title('Relative Humidity Changes in Freddy Genesis Box (110-120°E, 10-20°S)', ...
    'FontSize', 16, 'FontWeight', 'bold');
xlabel('Date', 'FontSize', 14);
ylabel('Relative Humidity (%)', 'FontSize', 14);
grid on;
box on;

% 设置x轴刻度（每两天一个刻度）
date_ticks = start_date:days(2):end_date;
xticks(date_ticks);
datetick('x', 'mm/dd', 'keepticks');
xtickangle(45);

% 设置y轴范围
y_min = min([rh_500_filtered; rh_700_filtered; rh_850_filtered]) - 5;
y_max = max([rh_500_filtered; rh_700_filtered; rh_850_filtered]) + 5;
ylim([max(y_min, 0), min(y_max, 100)]);  % 相对湿度范围0-100%

% 添加图例
legend('Location', 'best', 'FontSize', 12);

% 添加文本框显示区域信息
text(0.02, 0.98, sprintf('Region: %.0f-%.0f°E, %.0f-%.0f°S', ...
    lon_range(1), lon_range(2), abs(lat_range(1)), abs(lat_range(2))), ...
    'Units', 'normalized', 'FontSize', 12, 'VerticalAlignment', 'top', ...
    'BackgroundColor', 'w', 'EdgeColor', 'k');

% 添加时间范围信息
text(0.02, 0.92, sprintf('Time: %s to %s', ...
    datestr(start_date, 'mm/dd/yyyy'), datestr(end_date, 'mm/dd/yyyy')), ...
    'Units', 'normalized', 'FontSize', 12, 'VerticalAlignment', 'top', ...
    'BackgroundColor', 'w', 'EdgeColor', 'k');

hold off;

%% 5. 保存图形
output_filename = 'Freddy_GenesisBox_RelativeHumidity_Fig8a.png';
print(gcf, output_filename, '-dpng', '-r300');
fprintf('图形已保存为: %s\n', output_filename);

%% 6. 显示数据统计信息
fprintf('\n=== 数据统计信息 ===\n');
fprintf('时间范围: %s 到 %s\n', datestr(min(time_dates_filtered)), ...
    datestr(max(time_dates_filtered)));
fprintf('总数据点数: %d\n', length(time_dates_filtered));
fprintf('时间间隔: 6小时\n\n');

fprintf('相对湿度统计 (区域平均):\n');
fprintf('%-10s: 最小值 = %.2f%%, 最大值 = %.2f%%, 平均值 = %.2f%%\n', ...
    '500 hPa', min(rh_500_filtered), max(rh_500_filtered), mean(rh_500_filtered));
fprintf('%-10s: 最小值 = %.2f%%, 最大值 = %.2f%%, 平均值 = %.2f%%\n', ...
    '700 hPa', min(rh_700_filtered), max(rh_700_filtered), mean(rh_700_filtered));
fprintf('%-10s: 最小值 = %.2f%%, 最大值 = %.2f%%, 平均值 = %.2f%%\n', ...
    '850 hPa', min(rh_850_filtered), max(rh_850_filtered), mean(rh_850_filtered));

%% 7. 额外可视化：相对湿度随时间的变化趋势
figure('Position', [100, 100, 1400, 800]);

% 创建子图
subplot(2, 2, 1);
plot(time_dates_filtered, rh_500_filtered, 'b-', 'LineWidth', 2);
title('500 hPa Relative Humidity');
xlabel('Date'); ylabel('RH (%)');
grid on; box on;
xticks(date_ticks);
datetick('x', 'mm/dd', 'keepticks');
xtickangle(45);
ylim([0, 100]);

subplot(2, 2, 2);
plot(time_dates_filtered, rh_700_filtered, 'r-', 'LineWidth', 2);
title('700 hPa Relative Humidity');
xlabel('Date'); ylabel('RH (%)');
grid on; box on;
xticks(date_ticks);
datetick('x', 'mm/dd', 'keepticks');
xtickangle(45);
ylim([0, 100]);

subplot(2, 2, 3);
plot(time_dates_filtered, rh_850_filtered, 'g-', 'LineWidth', 2);
title('850 hPa Relative Humidity');
xlabel('Date'); ylabel('RH (%)');
grid on; box on;
xticks(date_ticks);
datetick('x', 'mm/dd', 'keepticks');
xtickangle(45);
ylim([0, 100]);

% 三个层次叠加图
subplot(2, 2, 4);
hold on;
plot(time_dates_filtered, rh_500_filtered, 'b-', 'LineWidth', 2, 'DisplayName', '500 hPa');
plot(time_dates_filtered, rh_700_filtered, 'r-', 'LineWidth', 2, 'DisplayName', '700 hPa');
plot(time_dates_filtered, rh_850_filtered, 'g-', 'LineWidth', 2, 'DisplayName', '850 hPa');
yline(rh_threshold, '--', 'Color', [1, 0.5, 0], 'LineWidth', 2, 'DisplayName', '81% RH');
title('All Levels Comparison');
xlabel('Date'); ylabel('RH (%)');
grid on; box on;
legend('Location', 'best');
xticks(date_ticks);
datetick('x', 'mm/dd', 'keepticks');
xtickangle(45);
ylim([0, 100]);

sgtitle('Relative Humidity Analysis for Tropical Cyclone Freddy Genesis Box', 'FontSize', 16, 'FontWeight', 'bold');

% 保存第二个图形
output_filename2 = 'Freddy_RH_Analysis_Detailed.png';
print(gcf, output_filename2, '-dpng', '-r300');
fprintf('详细分析图形已保存为: %s\n', output_filename2);

fprintf('\n=== 处理完成 ===\n');