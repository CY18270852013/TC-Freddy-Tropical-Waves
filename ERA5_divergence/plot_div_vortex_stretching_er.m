%% 绘制Freddy genesis box的ER散度和涡旋拉伸项时间序列图
clear; clc; close all;

%% 1. 设置参数
% Freddy genesis box的范围
lon_min = 110;  % 东经110°
lon_max = 120;  % 东经120°
lat_min = -20;  % 南纬20°
lat_max = -10;  % 南纬10°

% 时间范围 (2023年)
start_date = datetime(2023, 2, 1, 0, 0, 0);
end_date = datetime(2023, 2, 12, 18, 0, 0);  % 最后时间点为2月12日18时

% 数据文件路径
er_div_file = "E:\Results_of_Freddy\divergence_anomaly_6hourly\divergence_anomaly_for_ER_6hourly_20220101_20231231.nc";
dv_files = {
    'E:\Original_Data_of_Freddy\ERA5_dv_q_uv_200901_202312_every_6hours\202301_dv.nc';
    'E:\Original_Data_of_Freddy\ERA5_dv_q_uv_200901_202312_every_6hours\202302_dv.nc';
    'E:\Original_Data_of_Freddy\ERA5_dv_q_uv_200901_202312_every_6hours\202303_dv.nc'
};

% 科氏参数常数
Omega = 7.2921e-5;  % 地球自转角速度 (rad/s)

%% 2. 读取ER散度异常数据
fprintf('正在读取ER散度异常数据...\n');

% 读取ER数据
er_lat = ncread(er_div_file, 'latitude');
er_lon = ncread(er_div_file, 'longitude');
er_time = ncread(er_div_file, 'time');
er_div_anom = ncread(er_div_file, 'divergence_anomaly_er');

% 将时间转换为datetime格式 (days since 0000-01-01 00:00:00)
% 注意: MATLAB的datetime从0000年1月1日开始
er_datetime = datetime(0, 1, 1) + days(er_time) - days(1);

% 提取2023年2月1日至2月12日的数据
time_mask = (er_datetime >= start_date) & (er_datetime <= end_date);
er_time_subset = er_time(time_mask);
er_datetime_subset = er_datetime(time_mask);
er_div_anom_subset = er_div_anom(:, :, time_mask);

% 查找在目标区域的索引
lon_idx = find(er_lon >= lon_min & er_lon <= lon_max);
lat_idx = find(er_lat >= lat_min & er_lat <= lat_max);

% 提取目标区域的数据
er_div_box = er_div_anom_subset(lon_idx, lat_idx, :);

% 计算区域平均值 (空间平均)
er_div_mean = squeeze(mean(mean(er_div_box, 1), 2));

fprintf('ER数据读取完成，时间点数量: %d\n', length(er_datetime_subset));

%% 3. 读取ERA5原始数据并计算绝对涡度
fprintf('正在读取ERA5原始数据并计算绝对涡度...\n');

% 初始化存储变量
all_vorticity = [];
all_times = [];

% 循环读取三个月的数据文件
for i = 1:length(dv_files)
    fprintf('正在处理文件: %s\n', dv_files{i});
    
    % 读取数据
    vo = ncread(dv_files{i}, 'vo');  % 相对涡度 (s^-1)
    vo_time = ncread(dv_files{i}, 'valid_time');  % 秒 since 1970-01-01
    lat = ncread(dv_files{i}, 'latitude');
    lon = ncread(dv_files{i}, 'longitude');
    pressure_levels = ncread(dv_files{i}, 'pressure_level');  % 气压层
    
    % 将时间转换为datetime格式
    vo_datetime = datetime(1970, 1, 1) + seconds(vo_time);
    
    % 提取2023年2月1日至2月12日的数据
    time_mask_vo = (vo_datetime >= start_date) & (vo_datetime <= end_date);
    
    if sum(time_mask_vo) == 0
        fprintf('文件 %s 中没有目标时间段的数据，跳过\n', dv_files{i});
        continue;
    end
    
    vo_datetime_subset = vo_datetime(time_mask_vo);
    vo_subset = vo(:, :, :, time_mask_vo);
    
    % 查找850 hPa层的索引
    level_idx = find(pressure_levels == 850);
    if isempty(level_idx)
        [~, level_idx] = min(abs(pressure_levels - 850));
        fprintf('注意: 未找到精确的850 hPa层，使用最接近的层: %.1f hPa\n', pressure_levels(level_idx));
    end
    
    % 提取850 hPa的相对涡度
    vo_850 = squeeze(vo_subset(:, :, level_idx, :));
    
    % 查找在目标区域的索引
    lon_idx_vo = find(lon >= lon_min & lon <= lon_max);
    lat_idx_vo = find(lat >= lat_min & lat <= lat_max);
    
    % 提取目标区域的数据
    vo_box = vo_850(lon_idx_vo, lat_idx_vo, :);
    
    % 计算科氏参数f = 2Ωsinφ
    % 注意: lat是纬度(度)，需要转换为弧度
    lat_rad = deg2rad(lat(lat_idx_vo));  % 转换为弧度
    
    % 为每个纬度点创建科氏参数数组
    f_array = 2 * Omega * sin(lat_rad);  % rad/s
    
    % 将科氏参数扩展到与vo_box相同的维度
    [lon_size, lat_size, time_size] = size(vo_box);
    f_expanded = repmat(reshape(f_array, [1, lat_size, 1]), [lon_size, 1, time_size]);
    
    % 计算绝对涡度: η = ζ + f
    abs_vorticity = vo_box + f_expanded;  % s^-1
    
    % 计算区域平均值 (空间平均)
    abs_vort_mean = squeeze(mean(mean(abs_vorticity, 1), 2));
    
    % 存储结果
    all_vorticity = [all_vorticity; abs_vort_mean];
    all_times = [all_times; vo_datetime_subset];
    
    fprintf('文件 %s 处理完成，时间点数量: %d\n', dv_files{i}, length(vo_datetime_subset));
end

%% 4. 时间对齐和涡旋拉伸项计算
fprintf('正在进行时间对齐和涡旋拉伸项计算...\n');

% 确保时间点对齐
% 由于两种数据都是6小时间隔，我们可以找到共同的时间点
common_times = intersect(er_datetime_subset, all_times);

if isempty(common_times)
    fprintf('错误: 没有共同的时间点!\n');
    return;
end

fprintf('找到 %d 个共同的时间点\n', length(common_times));

% 提取共同时间点的数据
er_div_mean_aligned = zeros(length(common_times), 1);
abs_vort_mean_aligned = zeros(length(common_times), 1);

for i = 1:length(common_times)
    % ER数据
    er_idx = find(er_datetime_subset == common_times(i));
    if ~isempty(er_idx)
        er_div_mean_aligned(i) = er_div_mean(er_idx);
    end
    
    % 绝对涡度数据
    vort_idx = find(all_times == common_times(i));
    if ~isempty(vort_idx)
        abs_vort_mean_aligned(i) = all_vorticity(vort_idx);
    end
end

% 计算涡旋拉伸项: η × (-∇·V')
% vortex stretching = 绝对涡度 × (-ER散度)
vortex_stretching = abs_vort_mean_aligned .* (-er_div_mean_aligned);  % s^-2

%% 5. 数据范围分析和y轴设置
% 分析数据范围以确定合适的y轴刻度
er_range = [min(er_div_mean_aligned), max(er_div_mean_aligned)];
vortex_range = [min(vortex_stretching), max(vortex_stretching)];

fprintf('\n数据范围分析:\n');
fprintf('ER散度异常范围: [%.3e, %.3e] s^-1\n', er_range(1), er_range(2));
fprintf('涡旋拉伸项范围: [%.3e, %.3e] s^-2\n', vortex_range(1), vortex_range(2));

% 计算合适的y轴范围（增加10%的边距）
er_ymin = min(er_div_mean_aligned) * 1e6 - 0.2;
er_ymax = max(er_div_mean_aligned) * 1e6 + 0.2;

% 涡旋拉伸项转换为10^-10 s^-2
vortex_scaled = vortex_stretching * 1e10;
vortex_ymin = min(vortex_scaled) - 0.2;
vortex_ymax = max(vortex_scaled) + 0.2;

% 确保y轴范围对称，使零线居中
er_abs_max = max(abs([er_ymin, er_ymax]));
er_ymin = -er_abs_max;
er_ymax = er_abs_max;

vortex_abs_max = max(abs([vortex_ymin, vortex_ymax]));
vortex_ymin = -vortex_abs_max;
vortex_ymax = vortex_abs_max;

%% 6. 绘图
fprintf('正在绘图...\n');

% 创建图形
figure('Position', [100, 100, 1000, 600]);

% 绘制双y轴图
yyaxis left;
plot(common_times, er_div_mean_aligned * 1e6, '-', 'Color', [0.1, 0.3, 0.8], 'LineWidth', 2);  % 转换为10^-6 s^-1
ylabel('ER Low-Level Divergence Anomaly (10^{-6} s^{-1})', 'FontSize', 12, 'FontWeight', 'bold');
ylim([er_ymin, er_ymax]);  % 使用计算的范围
grid on;

yyaxis right;
plot(common_times, vortex_stretching * 1e10, '-', 'Color', [0.85, 0.33, 0.10], 'LineWidth', 2);  % 转换为10^-10 s^-2
ylabel('Vortex Stretching Term (10^{-10} s^{-2})', 'FontSize', 12, 'FontWeight', 'bold');
ylim([vortex_ymin, vortex_ymax]);  % 使用计算的范围

% 设置x轴
xlabel('Date (2023)', 'FontSize', 12, 'FontWeight', 'bold');
xlim([common_times(1), common_times(end)]);
datetick('x', 'mm/dd', 'keeplimits');
% xtickangle(45);

% 每两天一个刻度
xt = common_times(1):days(2):common_times(end);
xticks(xt);
xticklabels(datestr(xt, 'mm/dd'));

% 设置标题
title('ER Influence on Vorticity in Freddy Genesis Box (110-120°E, 10-20°S)', ...
    'FontSize', 14, 'FontWeight', 'bold');

% 添加图例
legend({'ER Divergence Anomaly (850 hPa)', 'Vortex Stretching Term'}, ...
    'Location', 'best', 'FontSize', 11);

% 添加零线
% yyaxis left;
% hold on;
% yline(0, 'k--', 'LineWidth', 0.5);
% hold off;
% 
% yyaxis right;
% hold on;
% yline(0, 'k--', 'LineWidth', 0.5);
% hold off;

% 添加网格
grid on;

%% 7. 保存图像
output_filename = 'Freddy_Genesis_Box_ER_Vortex_Stretching.png';
print(gcf, output_filename, '-dpng', '-r300');
fprintf('图像已保存为: %s\n', output_filename);

%% 8. 显示统计信息
fprintf('\n=== 统计信息 ===\n');
fprintf('时间范围: %s 到 %s\n', datestr(common_times(1)), datestr(common_times(end)));
fprintf('时间点数量: %d\n', length(common_times));
fprintf('ER散度异常范围: [%.3e, %.3e] s^-1\n', min(er_div_mean_aligned), max(er_div_mean_aligned));
fprintf('涡旋拉伸项范围: [%.3e, %.3e] s^-2\n', min(vortex_stretching), max(vortex_stretching));
fprintf('平均绝对涡度: %.3e s^-1\n', mean(abs_vort_mean_aligned));

% 计算并显示峰值信息
[er_max, er_max_idx] = max(abs(er_div_mean_aligned));
[vortex_max, vortex_max_idx] = max(abs(vortex_stretching));
fprintf('ER散度异常最大绝对值: %.3e s^-1 出现在 %s\n', er_max, datestr(common_times(er_max_idx)));
fprintf('涡旋拉伸项最大绝对值: %.3e s^-2 出现在 %s\n', vortex_max, datestr(common_times(vortex_max_idx)));

% 绘制两个变量的时间序列分别查看
figure('Position', [100, 100, 1200, 400]);

subplot(1, 3, 1);
plot(common_times, er_div_mean_aligned * 1e6, 'b-', 'LineWidth', 1.5);
xlabel('Date');
ylabel('ER Div Anom (10^{-6} s^{-1})');
title('ER Divergence Anomaly');
datetick('x', 'mm/dd', 'keeplimits');
% xtickangle(45);
grid on;

subplot(1, 3, 2);
plot(common_times, abs_vort_mean_aligned * 1e5, 'g-', 'LineWidth', 1.5);  % 转换为10^-5 s^-1
xlabel('Date');
ylabel('Abs Vorticity (10^{-5} s^{-1})');
title('Absolute Vorticity (850 hPa)');
datetick('x', 'mm/dd', 'keeplimits');
% xtickangle(45);
grid on;

subplot(1, 3, 3);
plot(common_times, vortex_stretching * 1e10, 'r-', 'LineWidth', 1.5);  % 转换为10^-10 s^-2
xlabel('Date');
ylabel('Vortex Stretching (10^{-10} s^{-2})');
title('Vortex Stretching Term');
datetick('x', 'mm/dd', 'keeplimits');
% xtickangle(45);
grid on;

sgtitle('Individual Time Series in Freddy Genesis Box', 'FontSize', 14, 'FontWeight', 'bold');

% 保存第二个图
print(gcf, 'ER_Freddy_Individual_Time_Series.png', '-dpng', '-r300');

fprintf('\n绘图完成!\n');