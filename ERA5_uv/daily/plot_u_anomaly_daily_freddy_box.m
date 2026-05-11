%% 清空环境
clear; clc; close all;

%% 文件路径设置
data_path = 'E:\Results_of_Freddy\u_v_daily\';

files = {
    fullfile(data_path, 'u_v_anomaly_daily_20220101_20231231.nc');          % 原始风场异常
    fullfile(data_path, 'u_v_anomaly_for_MJO_daily_20220101_20231231.nc');  % MJO滤波
    fullfile(data_path, 'u_v_anomaly_for_Kelvin_daily_20220101_20231231.nc'); % Kelvin滤波
    fullfile(data_path, 'u_v_anomaly_for_MRG_daily_20220101_20231231.nc');   % MRG滤波
    fullfile(data_path, 'u_v_anomaly_for_ER_daily_20220101_20231231.nc');    % ER滤波
};

%% 区域设置
lon_range = [110, 120];  % 东经110-120°
lat_range = [-20, -10];  % 南纬10-20° (注意：负值表示南纬)

% 使用datetime格式的时间
date_start = datetime('2023-02-01');
date_end = datetime('2023-02-12');

%% 读取第一个文件获取基本维度信息
fprintf('读取基本维度信息...\n');
% 第一个文件的维度名不同
lon_all = ncread(files{1}, 'longitude');  % 720个点 (0-359.5)
lat_all = ncread(files{1}, 'latitude');   % 121个点 (30到-30)
time_raw = ncread(files{1}, 'time');      % 730个点

fprintf('经度数量: %d (%.1f°到%.1f°)\n', length(lon_all), min(lon_all), max(lon_all));
fprintf('纬度数量: %d (%.1f°到%.1f°)\n', length(lat_all), min(lat_all), max(lat_all));
fprintf('时间数量: %d\n', length(time_raw));

% 将时间从'days since 2009-01-01 00:00:00'转换为datetime
time_dates = datetime(time_raw, 'ConvertFrom', 'datenum', 'Format','yyyy-MM-dd');

% 选择时间范围
time_idx = time_dates >= date_start & time_dates <= date_end;
time_plot = time_dates(time_idx);
time_count = sum(time_idx);
fprintf('时间范围: %s 到 %s, 共%d个时间点\n', ...
    datestr(date_start), datestr(date_end), time_count);

% 找到目标区域的索引
lat_idx = find(lat_all >= lat_range(1) & lat_all <= lat_range(2));
lon_idx = find(lon_all >= lon_range(1) & lon_all <= lon_range(2));

fprintf('目标纬度范围: %.1f°到%.1f°, 找到%d个点\n', ...
    min(lat_all(lat_idx)), max(lat_all(lat_idx)), length(lat_idx));
fprintf('目标经度范围: %.1f°到%.1f°, 找到%d个点\n', ...
    min(lon_all(lon_idx)), max(lon_all(lon_idx)), length(lon_idx));

if isempty(lat_idx) || isempty(lon_idx)
    error('未找到指定区域内的数据点。请检查经纬度范围。');
end

%% 读取原始U风异常数据（全部数据）
fprintf('\n读取原始U风异常数据...\n');
u_all = ncread(files{1}, 'u_anomaly');
fprintf('原始U风数据维度: 经度=%d, 纬度=%d, 时间=%d\n', ...
    size(u_all, 1), size(u_all, 2), size(u_all, 3));

% 替换填充值（NaN已经是填充值，直接使用）
u_all(isnan(u_all)) = NaN;  % 明确处理NaN

% 选择时间维度的数据
u_all_time = u_all(:,:,time_idx);

% 选择目标区域的数据
% 注意维度顺序: (longitude, latitude, time)
u_region = u_all_time(lon_idx, lat_idx, :);

% 计算区域平均时间序列
u_region_mean = zeros(time_count, 1);
for t = 1:time_count
    current_data = u_region(:,:,t);
    u_region_mean(t) = nanmean(current_data(:));
end
fprintf('原始U风数据处理完成\n');

%% 读取各滤波后的U风异常数据
wave_names = {'MJO', 'Kelvin', 'MRG', 'ER'};
wave_colors = {'k', 'b', [0, 0.6, 0], 'r'}; % 黑、蓝、绿、红
u_waves = zeros(time_count, length(wave_names));

% 对于每个滤波文件，变量名和维度名略有不同
for i = 1:length(wave_names)
    fprintf('\n读取%s波U风数据...\n', wave_names{i});
    file = files{i+1};
    
    % 读取滤波文件的纬度和经度
    lon_wave = ncread(file, 'lon');
    lat_wave = ncread(file, 'lat');
    
    % 确保与原始数据一致
    if ~isequal(lon_wave, lon_all)
        fprintf('警告: %s波数据的经度网格与原始数据不一致\n', wave_names{i});
    end
    if ~isequal(lat_wave, lat_all)
        fprintf('警告: %s波数据的纬度网格与原始数据不一致\n', wave_names{i});
    end
    
    % 动态确定U风变量名
    var_names_wave = ncinfo(file).Variables;
    u_var_name = '';
    
    % 寻找U风变量名
    for j = 1:length(var_names_wave)
        var_name_candidate = var_names_wave(j).Name;
        if contains(var_name_candidate, 'u_anomaly', 'IgnoreCase', true) && ...
           contains(var_name_candidate, wave_names{i}, 'IgnoreCase', true)
            u_var_name = var_name_candidate;
            break;
        end
    end
    
    if isempty(u_var_name)
        % 尝试默认名称
        u_var_name = sprintf('u_anomaly_%s', lower(wave_names{i}));
    end
    
    fprintf('  使用变量名: %s\n', u_var_name);
    
    % 读取全部数据
    u_wave_all = ncread(file, u_var_name);
    fprintf('  %s数据维度: %dx%dx%d\n', wave_names{i}, ...
        size(u_wave_all, 1), size(u_wave_all, 2), size(u_wave_all, 3));
    
    % 处理NaN值
    u_wave_all(isnan(u_wave_all)) = NaN;
    
    % 选择时间维度的数据
    u_wave_time = u_wave_all(:,:,time_idx);
    
    % 选择目标区域的数据
    u_wave_region = u_wave_time(lon_idx, lat_idx, :);
    
    % 计算区域平均时间序列
    for t = 1:time_count
        current_wave_data = u_wave_region(:,:,t);
        u_waves(t, i) = nanmean(current_wave_data(:));
    end
    fprintf('%s波U风数据处理完成\n', wave_names{i});
end

%% 计算所有波动的总和
u_sum = sum(u_waves, 2, 'omitnan');

%% 绘制时间序列图
figure('Position', [100, 100, 1000, 600], 'Color', 'white');

% 绘制各波动分量
hold on;
for i = 1:length(wave_names)
    plot(time_plot, u_waves(:, i), 'Color', wave_colors{i}, 'LineWidth', 1.5, 'DisplayName', wave_names{i});
end

% 绘制总和
plot(time_plot, u_sum, 'Color', [0.5, 0, 0.8], 'LineWidth', 2, 'DisplayName', 'Sum of All Waves');

% 绘制原始U风异常
plot(time_plot, u_region_mean, '--', 'Color', 'k', 'LineWidth', 2, 'DisplayName', 'U-WIND Anomaly');

hold off;

%% 设置图形属性
xlim([date_start, date_end]);

% 设置横轴刻度：每两天一个刻度
xt = date_start:days(2):date_end;
xticks(xt);
% 设置刻度标签格式
xticklabels(cellstr(datestr(xt, 'mm/dd')));

xlabel('Date (2023)', 'FontSize', 12);
ylabel('Zonal Wind Anomaly (m s^{-1})', 'FontSize', 12);
title('850 hPa Zonal Wind Anomaly Contributions in Freddy Genesis Box (110°E-120°E, 10°S-20°S)', ...
    'FontSize', 14, 'FontWeight', 'bold');

legend('Location', 'best', 'FontSize', 10);
grid on;
set(gca, 'FontSize', 11, 'Box', 'on');

%% 调整纵轴范围
% 收集所有有效数据
all_data = [u_region_mean; u_sum; u_waves(:)];
all_data_valid = all_data(~isnan(all_data));

if ~isempty(all_data_valid)
    y_min = min(all_data_valid);
    y_max = max(all_data_valid);
    
    % 添加一些边距
    y_range = y_max - y_min;
    if y_range > 0
        y_min = y_min - 0.1 * y_range;
        y_max = y_max + 0.1 * y_range;
    else
        y_min = y_min - 0.5;
        y_max = y_max + 0.5;
    end
    
    % 确保包含零线
    if y_min > 0
        y_min = -0.1;
    end
    if y_max < 0
        y_max = 0.1;
    end
    
    ylim([y_min, y_max]);
else
    warning('所有数据都是NaN，请检查数据质量');
end

%% 添加参考线
hold on;
plot([date_start, date_end], [0, 0], 'k--', 'LineWidth', 0.5, 'HandleVisibility', 'off');
hold off;

%% 保存图片
saveas(gcf, 'Freddy_Genesis_U_Wind_Anomaly_Contributions.png');
fprintf('\n图片已保存为 Freddy_Genesis_U_Wind_Anomaly_Contributions.png\n');

%% 显示数据统计信息
fprintf('\n数据统计信息:\n');
fprintf('时间范围: %s 到 %s\n', datestr(date_start), datestr(date_end));
fprintf('数据点数: %d (每日平均)\n', length(time_plot));
fprintf('区域范围: 经度 %.1f°E-%.1f°E, 纬度 %.1f°S-%.1f°S\n', ...
    lon_range(1), lon_range(2), -lat_range(1), -lat_range(2));
fprintf('网格点数: %d个经度点 × %d个纬度点\n', length(lon_idx), length(lat_idx));

% 原始U风异常统计
valid_u = u_region_mean(~isnan(u_region_mean));
if ~isempty(valid_u)
    fprintf('\nU风异常统计:\n');
    fprintf('  范围: [%.3f, %.3f] m s^{-1}\n', min(valid_u), max(valid_u));
    fprintf('  均值: %.3f m s^{-1}\n', mean(valid_u));
    fprintf('  标准差: %.3f m s^{-1}\n', std(valid_u));
else
    fprintf('\nU风异常: 所有数据都是NaN\n');
end

% 各波列贡献统计
fprintf('\n各波列贡献统计:\n');
for i = 1:length(wave_names)
    valid_wave_data = u_waves(:, i);
    valid_wave_data = valid_wave_data(~isnan(valid_wave_data));
    if ~isempty(valid_wave_data)
        fprintf('  %s: [%.3f, %.3f] m s^{-1}, 均值: %.3f, 标准差: %.3f\n', wave_names{i}, ...
            min(valid_wave_data), max(valid_wave_data), ...
            mean(valid_wave_data), std(valid_wave_data));
    else
        fprintf('  %s: 所有数据都是NaN\n', wave_names{i});
    end
end

% 总和统计
valid_sum = u_sum(~isnan(u_sum));
if ~isempty(valid_sum)
    fprintf('\n总和统计:\n');
    fprintf('  范围: [%.3f, %.3f] m s^{-1}\n', min(valid_sum), max(valid_sum));
    fprintf('  均值: %.3f m s^{-1}\n', mean(valid_sum));
else
    fprintf('\n总和: 所有数据都是NaN\n');
end

%% 保存数据到MAT文件
save('Freddy_U_Wind_Data.mat', 'time_plot', 'u_region_mean', ...
    'u_waves', 'u_sum', 'wave_names', 'lon_range', 'lat_range', ...
    'lon_all', 'lat_all', 'time_dates');
fprintf('\n数据已保存到 Freddy_U_Wind_Data.mat\n');

%% 创建补充图：分开展示各分量
figure('Position', [100, 100, 1200, 800], 'Color', 'white');

% 创建子图：原始异常和总和
subplot(3, 2, 1);
plot(time_plot, u_region_mean, '--', 'Color', 'k', 'LineWidth', 2);
xlim([date_start, date_end]);
xticks(xt);
xticklabels(cellstr(datestr(xt, 'mm/dd')));
ylabel('m s^{-1}', 'FontSize', 10);
title('Total U-Wind Anomaly', 'FontSize', 11, 'FontWeight', 'bold');
grid on;
set(gca, 'FontSize', 9);

% 各波列分量子图
for i = 1:length(wave_names)
    subplot(3, 2, i+1);
    plot(time_plot, u_waves(:, i), 'Color', wave_colors{i}, 'LineWidth', 1.5);
    xlim([date_start, date_end]);
    xticks(xt);
    xticklabels(cellstr(datestr(xt, 'mm/dd')));
    ylabel('m s^{-1}', 'FontSize', 10);
    title(sprintf('%s Wave Contribution', wave_names{i}), 'FontSize', 11, 'FontWeight', 'bold');
    grid on;
    set(gca, 'FontSize', 9);
end

% 总和子图
subplot(3, 2, 6);
plot(time_plot, u_sum, 'Color', [0.5, 0, 0.8], 'LineWidth', 2);
xlim([date_start, date_end]);
xticks(xt);
xticklabels(cellstr(datestr(xt, 'mm/dd')));
ylabel('m s^{-1}', 'FontSize', 10);
title('Sum of All Wave Contributions', 'FontSize', 11, 'FontWeight', 'bold');
grid on;
set(gca, 'FontSize', 9);

sgtitle('850 hPa Zonal Wind Anomaly Contributions in Freddy Genesis Box (110°E-120°E, 10°S-20°S)', ...
    'FontSize', 14, 'FontWeight', 'bold');

saveas(gcf, 'U_Wind_Contributions_Subplots.png');
fprintf('补充图已保存为 U_Wind_Contributions_Subplots.png\n');