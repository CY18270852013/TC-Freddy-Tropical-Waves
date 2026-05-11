%% 清空环境
clear; clc; close all;

%% 文件路径设置
data_path = 'E:\Results_of_Freddy\VIMD_anomaly_6hourly\';

files = {
    fullfile(data_path, 'VIMD_anomaly_6hourly_20220101_20231231.nc');          % 原始VIMD异常
    fullfile(data_path, 'VIMD_anomaly_for_MJO_6hourly_20220101_20231231.nc');  % MJO滤波
    fullfile(data_path, 'VIMD_anomaly_for_Kelvin_6hourly_20220101_20231231.nc'); % Kelvin滤波
    fullfile(data_path, 'VIMD_anomaly_for_MRG_6hourly_20220101_20231231.nc');   % MRG滤波
    fullfile(data_path, 'VIMD_anomaly_for_ER_6hourly_20220101_20231231.nc');    % ER滤波
};

%% 区域设置
lon_range = [110, 120];  % 东经110-120°
lat_range = [-20, -10];  % 南纬10-20° (注意：负值表示南纬)

% 使用datetime格式的时间
date_start = datetime('2023-02-01');
date_end = datetime('2023-02-12');

%% 读取第一个文件获取基本维度信息
fprintf('读取基本维度信息...\n');
lon_all = ncread(files{1}, 'longitude');  % 720个点 (0-359.5)
lat_all = ncread(files{1}, 'latitude');   % 81个点 (10到-30)
time_raw = ncread(files{1}, 'time');      % 2920个点 (6小时数据)

fprintf('经度数量: %d (%.1f°到%.1f°)\n', length(lon_all), min(lon_all), max(lon_all));
fprintf('纬度数量: %d (%.1f°到%.1f°)\n', length(lat_all), min(lat_all), max(lat_all));
fprintf('时间数量: %d (6小时数据)\n', length(time_raw));

% 将时间从'seconds since 1970-01-01'转换为datetime
base_date = datetime(1970, 1, 1);
time_dates = base_date + seconds(time_raw);

fprintf('时间数据范围: %s 到 %s\n', datestr(min(time_dates)), datestr(max(time_dates)));

% 选择时间范围
time_idx = time_dates >= date_start & time_dates <= date_end;
time_plot = time_dates(time_idx);
time_count = sum(time_idx);
fprintf('选择时间范围: %s 到 %s, 共%d个时间点\n', ...
    datestr(date_start), datestr(date_end), time_count);

if time_count == 0
    error('没有找到指定时间范围内的数据');
end

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

%% 读取原始VIMD异常数据
fprintf('\n读取原始VIMD异常数据...\n');
vimd_all = ncread(files{1}, 'vimd_anomaly');
fprintf('原始VIMD数据维度: 经度=%d, 纬度=%d, 时间=%d\n', ...
    size(vimd_all, 1), size(vimd_all, 2), size(vimd_all, 3));

% 处理填充值 (NaN)
fill_value = NaN;  % 原始数据的填充值是NaN
vimd_all(isnan(vimd_all)) = NaN;

% 选择时间维度的数据
vimd_all_time = vimd_all(:,:,time_idx);

% 选择目标区域的数据
% 注意维度顺序: (longitude, latitude, time)
vimd_region = vimd_all_time(lon_idx, lat_idx, :);

% 计算区域平均时间序列
vimd_region_mean = zeros(time_count, 1);
for t = 1:time_count
    current_data = vimd_region(:,:,t);
    vimd_region_mean(t) = nanmean(current_data(:));
end
fprintf('原始VIMD数据处理完成\n');

%% 读取各滤波后的VIMD异常数据
wave_names = {'MJO', 'Kelvin', 'MRG', 'ER'};
wave_colors = {'k', 'b', [0, 0.6, 0], 'r'}; % 黑、蓝、绿、红
vimd_waves = zeros(time_count, length(wave_names));

for i = 1:length(wave_names)
    fprintf('\n读取%s波VIMD数据...\n', wave_names{i});
    file = files{i+1};
    
    % 动态确定VIMD变量名
    var_names_wave = ncinfo(file).Variables;
    vimd_var_name = '';
    
    % 寻找VIMD变量名
    for j = 1:length(var_names_wave)
        var_name_candidate = var_names_wave(j).Name;
        if contains(var_name_candidate, 'vimd_anomaly', 'IgnoreCase', true) && ...
           contains(var_name_candidate, wave_names{i}, 'IgnoreCase', true)
            vimd_var_name = var_name_candidate;
            break;
        end
    end
    
    if isempty(vimd_var_name)
        % 尝试默认名称
        vimd_var_name = sprintf('vimd_anomaly_%s', lower(wave_names{i}));
    end
    
    fprintf('  使用变量名: %s\n', vimd_var_name);
    
    % 读取全部数据
    vimd_wave_all = ncread(file, vimd_var_name);
    fprintf('  %s数据维度: %dx%dx%d\n', wave_names{i}, ...
        size(vimd_wave_all, 1), size(vimd_wave_all, 2), size(vimd_wave_all, 3));
    
    % 处理填充值 (注意：滤波数据的填充值是9.969209968386869e+36)
    fill_value_wave = 9.969209968386869e+36;
    vimd_wave_all(vimd_wave_all == fill_value_wave) = NaN;
    
    % 选择时间维度的数据
    vimd_wave_time = vimd_wave_all(:,:,time_idx);
    
    % 选择目标区域的数据
    vimd_wave_region = vimd_wave_time(lon_idx, lat_idx, :);
    
    % 计算区域平均时间序列
    for t = 1:time_count
        current_wave_data = vimd_wave_region(:,:,t);
        vimd_waves(t, i) = nanmean(current_wave_data(:));
    end
    fprintf('%s波VIMD数据处理完成\n', wave_names{i});
end

%% 计算所有波动的总和
vimd_sum = sum(vimd_waves, 2, 'omitnan');

%% 绘制时间序列图
figure('Position', [100, 100, 1000, 600], 'Color', 'white');

% 检查时间数据是否有效 - 使用isnat代替isnan来处理datetime数组
if isempty(time_plot) || all(isnat(time_plot))
    error('时间数据无效，无法绘图');
end

% 绘制各波动分量
hold on;
for i = 1:length(wave_names)
    plot(time_plot, vimd_waves(:, i), 'Color', wave_colors{i}, 'LineWidth', 1.5, 'DisplayName', wave_names{i});
end

% 绘制总和
plot(time_plot, vimd_sum, 'Color', [0.5, 0, 0.8], 'LineWidth', 2, 'DisplayName', 'Sum of All Waves');

% 绘制原始VIMD异常
plot(time_plot, vimd_region_mean, '--', 'Color', 'k', 'LineWidth', 2, 'DisplayName', 'VIMD Anomaly');

hold off;

%% 设置图形属性
% 确保有有效的时间数据
if ~isempty(time_plot) && ~all(isnat(time_plot))
    x_min = min(time_plot);
    x_max = max(time_plot);
    xlim([x_min, x_max]);
    
    % 设置横轴刻度：每两天一个刻度
    xt = x_min:days(2):x_max;
    if length(xt) > 20
        % 如果刻度太多，只显示部分
        xt = x_min:days(4):x_max;
    end
    xticks(xt);
    
    % 设置刻度标签格式
    xticklabels(cellstr(datestr(xt, 'mm/dd')));
else
    % 如果没有有效时间，使用索引
    xlim([0.5, time_count+0.5]);
    xticks(1:2:time_count);
    xlabel('Time Index', 'FontSize', 12);
end

xlabel('Date (2023)', 'FontSize', 12);
ylabel('VIMD Anomaly (kg m^{-2} s^{-1})', 'FontSize', 12);
title(["Vertically Integrated Moisture Divergence Anomaly Contributions", ...
       "in Freddy Genesis Box (110°E–120°E, 10°S–20°S)"], ...
      'FontSize', 14, 'FontWeight', 'bold');

legend('Location', 'best', 'FontSize', 10);
grid on;
set(gca, 'FontSize', 11, 'Box', 'on');

%% 调整纵轴范围
% 收集所有有效数据
all_data = [vimd_region_mean; vimd_sum; vimd_waves(:)];
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
        y_min = y_min - 1e-7;
        y_max = y_max + 1e-7;
    end
    
    % 确保包含零线
    if y_min > 0
        y_min = -0.1 * y_max;
    end
    if y_max < 0
        y_max = -0.1 * y_min;
    end
    
    ylim([y_min, y_max]);
else
    warning('所有数据都是NaN，请检查数据质量');
end

%% 添加参考线
hold on;
if ~isempty(time_plot) && ~all(isnat(time_plot))
    plot([x_min, x_max], [0, 0], 'k--', 'LineWidth', 0.5, 'HandleVisibility', 'off');
else
    plot([0.5, time_count+0.5], [0, 0], 'k--', 'LineWidth', 0.5, 'HandleVisibility', 'off');
end
hold off;

%% 保存图片
saveas(gcf, 'Freddy_Genesis_VIMD_Anomaly_Contributions_version2_2.png');
fprintf('\n图片已保存为 Freddy_Genesis_VIMD_Anomaly_Contributions_version2_2.png\n');

%% 显示数据统计信息
fprintf('\n数据统计信息:\n');
fprintf('时间范围: %s 到 %s\n', datestr(min(time_plot)), datestr(max(time_plot)));
fprintf('数据点数: %d (6小时分辨率)\n', length(time_plot));
fprintf('区域范围: 经度 %.1f°E-%.1f°E, 纬度 %.1f°S-%.1f°S\n', ...
    lon_range(1), lon_range(2), -lat_range(1), -lat_range(2));
fprintf('网格点数: %d个经度点 × %d个纬度点\n', length(lon_idx), length(lat_idx));

% 原始VIMD异常统计
valid_vimd = vimd_region_mean(~isnan(vimd_region_mean));
if ~isempty(valid_vimd)
    fprintf('\nVIMD异常统计:\n');
    fprintf('  范围: [%.2e, %.2e] kg m^{-2} s^{-1}\n', min(valid_vimd), max(valid_vimd));
    fprintf('  均值: %.2e kg m^{-2} s^{-1}\n', mean(valid_vimd));
    fprintf('  标准差: %.2e kg m^{-2} s^{-1}\n', std(valid_vimd));
else
    fprintf('\nVIMD异常: 所有数据都是NaN\n');
end

% 各波列贡献统计
fprintf('\n各波列贡献统计:\n');
for i = 1:length(wave_names)
    valid_wave_data = vimd_waves(:, i);
    valid_wave_data = valid_wave_data(~isnan(valid_wave_data));
    if ~isempty(valid_wave_data)
        fprintf('  %s: [%.2e, %.2e] kg m^{-2} s^{-1}, 均值: %.2e, 标准差: %.2e\n', wave_names{i}, ...
            min(valid_wave_data), max(valid_wave_data), ...
            mean(valid_wave_data), std(valid_wave_data));
    else
        fprintf('  %s: 所有数据都是NaN\n', wave_names{i});
    end
end

% 总和统计
valid_sum = vimd_sum(~isnan(vimd_sum));
if ~isempty(valid_sum)
    fprintf('\n总和统计:\n');
    fprintf('  范围: [%.2e, %.2e] kg m^{-2} s^{-1}\n', min(valid_sum), max(valid_sum));
    fprintf('  均值: %.2e kg m^{-2} s^{-1}\n', mean(valid_sum));
else
    fprintf('\n总和: 所有数据都是NaN\n');
end

%% 保存数据到MAT文件
% save('Freddy_VIMD_Data.mat', 'time_plot', 'vimd_region_mean', ...
%     'vimd_waves', 'vimd_sum', 'wave_names', 'lon_range', 'lat_range', ...
%     'lon_all', 'lat_all', 'time_dates');
% fprintf('\n数据已保存到 Freddy_VIMD_Data.mat\n');

%% 创建补充图：分开展示各分量
figure('Position', [100, 100, 1200, 800], 'Color', 'white');

% 创建子图：原始异常和总和
subplot(3, 2, 1);
plot(time_plot, vimd_region_mean, '--', 'Color', 'k', 'LineWidth', 2);
xlim([min(time_plot), max(time_plot)]);
xticks(xt);
xticklabels(cellstr(datestr(xt, 'mm/dd')));
ylabel('kg m^{-2} s^{-1}', 'FontSize', 10);
title('Total VIMD Anomaly', 'FontSize', 11, 'FontWeight', 'bold');
grid on;
set(gca, 'FontSize', 9);

% 各波列分量子图
for i = 1:length(wave_names)
    subplot(3, 2, i+1);
    plot(time_plot, vimd_waves(:, i), 'Color', wave_colors{i}, 'LineWidth', 1.5);
    xlim([min(time_plot), max(time_plot)]);
    xticks(xt);
    xticklabels(cellstr(datestr(xt, 'mm/dd')));
    ylabel('kg m^{-2} s^{-1}', 'FontSize', 10);
    title(sprintf('%s Wave Contribution', wave_names{i}), 'FontSize', 11, 'FontWeight', 'bold');
    grid on;
    set(gca, 'FontSize', 9);
end

% 总和子图
subplot(3, 2, 6);
plot(time_plot, vimd_sum, 'Color', [0.5, 0, 0.8], 'LineWidth', 2);
xlim([min(time_plot), max(time_plot)]);
xticks(xt);
xticklabels(cellstr(datestr(xt, 'mm/dd')));
ylabel('kg m^{-2} s^{-1}', 'FontSize', 10);
title('Sum of All Wave Contributions', 'FontSize', 11, 'FontWeight', 'bold');
grid on;
set(gca, 'FontSize', 9);

sgtitle('Vertically Integrated Moisture Divergence Anomaly Contributions in Freddy Genesis Box (110°E-120°E, 10°S-20°S)', ...
    'FontSize', 14, 'FontWeight', 'bold');

saveas(gcf, 'VIMD_Contributions_Subplots_version2_2.png');
fprintf('补充图已保存为 VIMD_Contributions_Subplots_version2_2.png\n');

%% 创建补充图：各波列相对贡献比例
figure('Position', [100, 100, 800, 400], 'Color', 'white');

% 计算各波列在整个时段内的平均贡献
wave_means = zeros(1, length(wave_names));
for i = 1:length(wave_names)
    valid_data = vimd_waves(:, i);
    valid_data = valid_data(~isnan(valid_data));
    if ~isempty(valid_data)
        wave_means(i) = mean(abs(valid_data));
    end
end

total_mean = sum(wave_means);

if total_mean > 0
    wave_percentages = 100 * wave_means / total_mean;
    
    % 创建颜色映射
    bar_colors = zeros(length(wave_names), 3);
    for i = 1:length(wave_names)
        if strcmp(wave_colors{i}, 'k')
            bar_colors(i, :) = [0, 0, 0];
        elseif strcmp(wave_colors{i}, 'b')
            bar_colors(i, :) = [0, 0, 1];
        elseif strcmp(wave_colors{i}, 'r')
            bar_colors(i, :) = [1, 0, 0];
        else
            bar_colors(i, :) = [0, 0.6, 0];
        end
    end
    
    % 绘制条形图
    bar_handles = bar(1:length(wave_names), wave_percentages);
    set(bar_handles, 'FaceColor', 'flat', 'CData', bar_colors);
    
    % 添加数值标签
    for i = 1:length(wave_names)
        text(i, wave_percentages(i) + 1, ...
            sprintf('%.1f%%', wave_percentages(i)), ...
            'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
    end
    
    xlabel('Wave Types', 'FontSize', 12);
    ylabel('Contribution Percentage (%)', 'FontSize', 12);
    title('Relative Contribution of Different Waves to VIMD Anomaly', ...
        'FontSize', 13, 'FontWeight', 'bold');
    set(gca, 'XTick', 1:length(wave_names), 'XTickLabel', wave_names, 'FontSize', 11);
    grid on;
    ylim([0, max(wave_percentages) * 1.2]);
    
    saveas(gcf, 'VIMD_Wave_Contribution_Percentages_version2_2.png');
    fprintf('补充图已保存为 VIMD_Wave_Contribution_Percentages_version2_2.png\n');
else
    fprintf('无法计算波列贡献比例：总贡献为零\n');
end