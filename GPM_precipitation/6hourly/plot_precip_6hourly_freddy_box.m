%% 清空环境
clear; clc; close all;

%% 文件路径设置
data_path = 'E:\Results_of_Freddy\GPM_anomaly_6hourly\';

files = {
    fullfile(data_path, 'GPM_anomaly_6hourly_20220901_20230630.nc');          % 原始降水异常
    fullfile(data_path, 'GPM_anomaly_6hourly_for_MJO_20220901_20230630.nc');  % MJO滤波
    fullfile(data_path, 'GPM_anomaly_6hourly_for_Kelvin_20220901_20230630.nc'); % Kelvin滤波
    fullfile(data_path, 'GPM_anomaly_6hourly_for_MRG_20220901_20230630.nc');   % MRG滤波
    fullfile(data_path, 'GPM_anomaly_6hourly_for_ER_20220901_20230630.nc');    % ER滤波
};

%% 区域设置
lon_range = [110, 120];  % 东经110-120°
lat_range = [-20, -10];  % 南纬10-20° (注意：负值表示南纬)

% 使用datetime格式的时间
date_start = datetime('2023-02-01');
date_end = datetime('2023-02-12');

%% 读取第一个文件获取基本维度信息
fprintf('读取基本维度信息...\n');
lat_all = ncread(files{1}, 'lat');  % 400个点 (-19.95到19.95)
lon_all = ncread(files{1}, 'lon');  % 3600个点 (-179.95到179.95)
time_raw = ncread(files{1}, 'time');

fprintf('纬度数量: %d (%.2f°到%.2f°)\n', length(lat_all), min(lat_all), max(lat_all));
fprintf('经度数量: %d (%.2f°到%.2f°)\n', length(lon_all), min(lon_all), max(lon_all));
fprintf('时间数量: %d\n', length(time_raw));

% 将时间从'days since 0000-01-01 00:00:00'转换为datetime
time_dates = datetime(0,1,1) + days(time_raw) - days(1);

% 选择时间范围
time_idx = time_dates >= date_start & time_dates < datetime('2023-02-13');
time_plot = time_dates(time_idx);
time_count = sum(time_idx);
fprintf('时间范围: %s 到 %s, 共%d个时间点\n', ...
    datestr(date_start), datestr(date_end), time_count);

%% 读取原始降水异常数据（全部数据）
fprintf('\n读取原始降水异常数据...\n');
var_names = ncinfo(files{1}).Variables;
var_name = var_names(1).Name;  % 第一个变量应该是降水异常

% 读取全部数据 - 维度是 (lat, lon, time) = (400, 3600, 1212)
precip_all = ncread(files{1}, var_name);
fprintf('原始数据维度: lat=%d, lon=%d, time=%d\n', ...
    size(precip_all, 1), size(precip_all, 2), size(precip_all, 3));

% 替换填充值
fill_value = -9999.9004;
precip_all(precip_all == fill_value) = NaN;

% 选择时间维度的数据
precip_all_time = precip_all(:,:,time_idx);

% 找到目标区域的索引
lat_idx = find(lat_all >= lat_range(1) & lat_all <= lat_range(2));
lon_idx = find(lon_all >= lon_range(1) & lon_all <= lon_range(2));

fprintf('目标纬度范围: %.2f°到%.2f°, 找到%d个点 (索引: %d到%d)\n', ...
    min(lat_all(lat_idx)), max(lat_all(lat_idx)), length(lat_idx), min(lat_idx), max(lat_idx));
fprintf('目标经度范围: %.2f°到%.2f°, 找到%d个点 (索引: %d到%d)\n', ...
    min(lon_all(lon_idx)), max(lon_all(lon_idx)), length(lon_idx), min(lon_idx), max(lon_idx));

if isempty(lat_idx) || isempty(lon_idx)
    error('未找到指定区域内的数据点。请检查经纬度范围。');
end

% 选择目标区域的数据
% 注意：数据维度是 (lat, lon, time)，所以索引顺序是 lat_idx, lon_idx
precip_region = precip_all_time(lat_idx, lon_idx, :);
fprintf('区域数据维度: lat=%d, lon=%d, time=%d\n', ...
    size(precip_region, 1), size(precip_region, 2), size(precip_region, 3));

% 计算区域平均时间序列
precip_region_mean = zeros(time_count, 1);
for t = 1:time_count
    % 获取当前时间点的数据
    current_data = precip_region(:,:,t);
    % 计算平均值，忽略NaN
    precip_region_mean(t) = nanmean(current_data(:));
end
fprintf('原始降水数据处理完成\n');

%% 读取各滤波后的降水异常数据
wave_names = {'MJO', 'Kelvin', 'MRG', 'ER'};
wave_colors = {'k', 'b', [0, 0.6, 0], 'r'}; % 黑、蓝、绿、红
precip_waves = zeros(time_count, length(wave_names));

for i = 1:length(wave_names)
    fprintf('\n读取%s波数据...\n', wave_names{i});
    file = files{i+1};
    
    % 动态确定变量名
    var_names_wave = ncinfo(file).Variables;
    var_name_wave = '';
    
    % 寻找合适的变量名
    for j = 1:length(var_names_wave)
        var_name_candidate = var_names_wave(j).Name;
        if contains(var_name_candidate, wave_names{i}, 'IgnoreCase', true) || ...
           contains(var_name_candidate, lower(wave_names{i}), 'IgnoreCase', true)
            var_name_wave = var_name_candidate;
            break;
        end
    end
    
    if isempty(var_name_wave)
        % 尝试默认名称
        if strcmp(wave_names{i}, 'MJO')
            var_name_wave = 'precipitation_anomaly_mjo';
        elseif strcmp(wave_names{i}, 'Kelvin')
            var_name_wave = 'precipitation_anomaly_kelvin';
        elseif strcmp(wave_names{i}, 'MRG')
            var_name_wave = 'precipitation_anomaly_mrg';
        elseif strcmp(wave_names{i}, 'ER')
            var_name_wave = 'precipitation_anomaly_er';
        end
    end
    
    fprintf('  使用变量名: %s\n', var_name_wave);
    
    % 读取全部数据
    precip_wave_all = ncread(file, var_name_wave);
    fprintf('  %s数据维度: %dx%dx%d\n', wave_names{i}, ...
        size(precip_wave_all, 1), size(precip_wave_all, 2), size(precip_wave_all, 3));
    
    % 替换填充值
    precip_wave_all(precip_wave_all == fill_value) = NaN;
    
    % 选择时间维度的数据
    precip_wave_time = precip_wave_all(:,:,time_idx);
    
    % 选择目标区域的数据 - 注意维度顺序是 (lat, lon, time)
    precip_wave_region = precip_wave_time(lat_idx, lon_idx, :);
    
    % 计算区域平均时间序列
    for t = 1:time_count
        current_wave_data = precip_wave_region(:,:,t);
        precip_waves(t, i) = nanmean(current_wave_data(:));
    end
    fprintf('%s波数据处理完成\n', wave_names{i});
end

%% 计算所有波动的总和
precip_sum = sum(precip_waves, 2, 'omitnan');

%% 绘制时间序列图
figure('Position', [100, 100, 1000, 600], 'Color', 'white');

% 绘制各波动分量
hold on;
for i = 1:length(wave_names)
    plot(time_plot, precip_waves(:, i), 'Color', wave_colors{i}, 'LineWidth', 1.5, 'DisplayName', wave_names{i});
end

% 绘制总和
plot(time_plot, precip_sum, 'Color', [0.5, 0, 0.8], 'LineWidth', 2, 'DisplayName', 'Sum of All Waves');

% 绘制原始降水异常
plot(time_plot, precip_region_mean, '--', 'Color', 'k', 'LineWidth', 2, 'DisplayName', 'Precipitation Anomaly');

hold off;

%% 设置图形属性
xlim([date_start, date_end]);

% 设置横轴刻度：每两天一个刻度
xt = date_start:days(2):date_end;
xticks(xt);
% 设置刻度标签格式
xticklabels(cellstr(datestr(xt, 'mm/dd')));

xlabel('Date (2023)', 'FontSize', 12);
ylabel('Precipitation Anomaly (mm/6h)', 'FontSize', 12);
title('Precipitation Anomaly Contributions in Freddy Genesis Box (110°E-120°E, 10°S-20°S)', ...
    'FontSize', 14, 'FontWeight', 'bold');

legend('Location', 'best', 'FontSize', 10);
grid on;
set(gca, 'FontSize', 11, 'Box', 'on');

%% 调整纵轴范围
% 收集所有有效数据
all_data = [precip_region_mean; precip_sum; precip_waves(:)];
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
        y_min = y_min - 0.1;
        y_max = y_max + 0.1;
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
saveas(gcf, 'Freddy_Genesis_Precipitation_Anomaly_Contributions.png');
fprintf('\n图片已保存为 Freddy_Genesis_Precipitation_Anomaly_Contributions.png\n');

%% 显示数据统计信息
fprintf('\n数据统计信息:\n');
fprintf('时间范围: %s 到 %s\n', datestr(date_start), datestr(date_end));
fprintf('数据点数: %d (6小时分辨率)\n', length(time_plot));
fprintf('区域范围: 经度 %.1f°E-%.1f°E, 纬度 %.1f°S-%.1f°S\n', ...
    lon_range(1), lon_range(2), -lat_range(1), -lat_range(2));
fprintf('网格点数: %d个纬度点 x %d个经度点\n', length(lat_idx), length(lon_idx));

% 原始降水异常统计
valid_precip = precip_region_mean(~isnan(precip_region_mean));
if ~isempty(valid_precip)
    fprintf('\n降水异常统计:\n');
    fprintf('  范围: [%.2f, %.2f] mm/6h\n', min(valid_precip), max(valid_precip));
    fprintf('  均值: %.2f mm/6h\n', mean(valid_precip));
    fprintf('  标准差: %.2f mm/6h\n', std(valid_precip));
else
    fprintf('\n降水异常: 所有数据都是NaN\n');
end

% 各波列贡献统计
fprintf('\n各波列贡献统计:\n');
for i = 1:length(wave_names)
    valid_wave_data = precip_waves(:, i);
    valid_wave_data = valid_wave_data(~isnan(valid_wave_data));
    if ~isempty(valid_wave_data)
        fprintf('  %s: [%.2f, %.2f] mm/6h, 均值: %.2f, 标准差: %.2f\n', wave_names{i}, ...
            min(valid_wave_data), max(valid_wave_data), ...
            mean(valid_wave_data), std(valid_wave_data));
    else
        fprintf('  %s: 所有数据都是NaN\n', wave_names{i});
    end
end

% 总和统计
valid_sum = precip_sum(~isnan(precip_sum));
if ~isempty(valid_sum)
    fprintf('\n总和统计:\n');
    fprintf('  范围: [%.2f, %.2f] mm/6h\n', min(valid_sum), max(valid_sum));
    fprintf('  均值: %.2f mm/6h\n', mean(valid_sum));
else
    fprintf('\n总和: 所有数据都是NaN\n');
end

%% 保存数据到MAT文件
save('Freddy_Precipitation_Data.mat', 'time_plot', 'precip_region_mean', ...
    'precip_waves', 'precip_sum', 'wave_names', 'lon_range', 'lat_range', ...
    'lon_all', 'lat_all', 'time_dates');
fprintf('\n数据已保存到 Freddy_Precipitation_Data.mat\n');












%% 创建补充图：分开展示各分量
figure('Position', [100, 100, 1200, 800], 'Color', 'white');

% 创建子图：原始异常和总和
subplot(3, 2, 1);
plot(time_plot, precip_region_mean, '--', 'Color', 'k', 'LineWidth', 2);
hold on;
plot([min(time_plot), max(time_plot)], [0, 0], 'k--', 'LineWidth', 0.5);
xlim([min(time_plot), max(time_plot)]);
xticks(xt);
xticklabels(cellstr(datestr(xt, 'mm/dd')));
ylabel('mm/6h', 'FontSize', 10);
title('Total Precipitation Anomaly', 'FontSize', 11, 'FontWeight', 'bold');
grid on;
set(gca, 'FontSize', 9);

% 各波列分量子图
for i = 1:length(wave_names)
    subplot(3, 2, i+1);
    plot(time_plot, precip_waves(:, i), 'Color', wave_colors{i}, 'LineWidth', 1.5);
    hold on;
    plot([min(time_plot), max(time_plot)], [0, 0], 'k--', 'LineWidth', 0.5);
    xlim([min(time_plot), max(time_plot)]);
    xticks(xt);
    xticklabels(cellstr(datestr(xt, 'mm/dd')));
    ylabel('mm/6h', 'FontSize', 10);
    title(sprintf('%s Wave Contribution', wave_names{i}), 'FontSize', 11, 'FontWeight', 'bold');
    grid on;
    set(gca, 'FontSize', 9);
end

% 总和子图
subplot(3, 2, 6);
plot(time_plot, precip_sum, 'Color', [0.5, 0, 0.8], 'LineWidth', 2);
hold on;
plot([min(time_plot), max(time_plot)], [0, 0], 'k--', 'LineWidth', 0.5);
xlim([min(time_plot), max(time_plot)]);
xticks(xt);
xticklabels(cellstr(datestr(xt, 'mm/dd')));
ylabel('mm/6h', 'FontSize', 10);
title('Sum of All Wave Contributions', 'FontSize', 11, 'FontWeight', 'bold');
grid on;
set(gca, 'FontSize', 9);

sgtitle('Precipitation Anomaly Contributions in Freddy Genesis Box (110°E-120°E, 10°S-20°S)', ...
    'FontSize', 14, 'FontWeight', 'bold');

saveas(gcf, 'Precipitation_Contributions_Subplots_6hourly.png');
fprintf('补充图1已保存为 Precipitation_Contributions_Subplots_6hourly.png\n');

%% 创建补充图：各波列相对贡献比例
figure('Position', [100, 100, 800, 400], 'Color', 'white');

% 计算各波列在整个时段内的平均贡献（取绝对值平均，表示平均强度）
wave_means = zeros(1, length(wave_names));
for i = 1:length(wave_names)
    valid_data = precip_waves(:, i);
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
        if ischar(wave_colors{i}) && strcmp(wave_colors{i}, 'k')
            bar_colors(i, :) = [0, 0, 0];
        elseif ischar(wave_colors{i}) && strcmp(wave_colors{i}, 'b')
            bar_colors(i, :) = [0, 0, 1];
        elseif ischar(wave_colors{i}) && strcmp(wave_colors{i}, 'r')
            bar_colors(i, :) = [1, 0, 0];
        else
            bar_colors(i, :) = [0, 0.6, 0]; % MRG的绿色
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
    title('Relative Contribution of Different Waves to Precipitation Anomaly (Average Intensity)', ...
        'FontSize', 13, 'FontWeight', 'bold');
    set(gca, 'XTick', 1:length(wave_names), 'XTickLabel', wave_names, 'FontSize', 11);
    grid on;
    ylim([0, max(wave_percentages) * 1.2]);
    
    saveas(gcf, 'Precipitation_Wave_Contribution_Percentages_6hourly.png');
    fprintf('补充图2已保存为 Precipitation_Wave_Contribution_Percentages_6hourly.png\n');
else
    fprintf('无法计算波列贡献比例：总贡献为零\n');
end

%% 创建补充图：原始异常与各波列总和的对比
figure('Position', [100, 100, 1000, 400], 'Color', 'white');

subplot(1, 2, 1);
plot(time_plot, precip_region_mean, 'b-', 'LineWidth', 2);
hold on;
plot(time_plot, precip_sum, 'r-', 'LineWidth', 2);
xlim([min(time_plot), max(time_plot)]);
xticks(xt);
xticklabels(cellstr(datestr(xt, 'mm/dd')));
ylabel('Precipitation Anomaly (mm/6h)', 'FontSize', 11);
title('Original vs. Wave Sum Comparison', 'FontSize', 12, 'FontWeight', 'bold');
legend({'Original Anomaly', 'Sum of Waves'}, 'Location', 'best', 'FontSize', 10);
grid on;
set(gca, 'FontSize', 10);

% 计算相关系数
valid_idx = ~isnan(precip_region_mean) & ~isnan(precip_sum);
if sum(valid_idx) > 1
    corr_coef = corrcoef(precip_region_mean(valid_idx), precip_sum(valid_idx));
    corr_value = corr_coef(1, 2);
    
    subplot(1, 2, 2);
    scatter(precip_region_mean(valid_idx), precip_sum(valid_idx), 50, 'filled', 'MarkerFaceColor', 'b');
    hold on;
    
    % 添加趋势线
    p = polyfit(precip_region_mean(valid_idx), precip_sum(valid_idx), 1);
    x_fit = linspace(min(precip_region_mean(valid_idx)), max(precip_region_mean(valid_idx)), 100);
    y_fit = polyval(p, x_fit);
    plot(x_fit, y_fit, 'r-', 'LineWidth', 2);
    
    % 添加对角线参考线
    max_val = max(abs([precip_region_mean(valid_idx); precip_sum(valid_idx)]));
    plot([-max_val, max_val], [-max_val, max_val], 'k--', 'LineWidth', 1);
    
    xlabel('Original Anomaly (mm/6h)', 'FontSize', 11);
    ylabel('Sum of Waves (mm/6h)', 'FontSize', 11);
    title(sprintf('Correlation: r = %.3f', corr_value), 'FontSize', 12, 'FontWeight', 'bold');
    grid on;
    axis equal;
    xlim([-max_val, max_val]);
    ylim([-max_val, max_val]);
    set(gca, 'FontSize', 10);
else
    fprintf('无法计算相关系数：有效数据点不足\n');
end

sgtitle('Precipitation Anomaly: Wave Contributions Analysis', 'FontSize', 14, 'FontWeight', 'bold');
saveas(gcf, 'Precipitation_Wave_Correlation_6hourly.png');
fprintf('补充图3已保存为 Precipitation_Wave_Correlation_6hourly.png\n');

%% 创建补充图：各波列的累积贡献
figure('Position', [100, 100, 1000, 600], 'Color', 'white');

% 计算累积贡献
cumulative_waves = zeros(time_count, length(wave_names));
for i = 1:length(wave_names)
    cumulative_waves(:, i) = cumsum(precip_waves(:, i), 'omitnan');
end

% 绘制累积贡献图
subplot(2, 1, 1);
hold on;
for i = 1:length(wave_names)
    plot(time_plot, cumulative_waves(:, i), 'Color', wave_colors{i}, 'LineWidth', 1.5, 'DisplayName', wave_names{i});
end
hold off;
xlim([min(time_plot), max(time_plot)]);
xticks(xt);
xticklabels(cellstr(datestr(xt, 'mm/dd')));
ylabel('Cumulative Precipitation Anomaly (mm)', 'FontSize', 11);
title('Cumulative Contribution of Each Wave', 'FontSize', 12, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 10);
grid on;
set(gca, 'FontSize', 10);

% 绘制累积贡献百分比图
subplot(2, 1, 2);
% 计算每个时间点的总累积贡献
total_cumulative = cumsum(precip_sum, 'omitnan');
wave_percentages_time = zeros(time_count, length(wave_names));

for i = 1:length(wave_names)
    wave_percentages_time(:, i) = 100 * cumulative_waves(:, i) ./ total_cumulative;
    wave_percentages_time(total_cumulative == 0, i) = 0; % 避免除以0
end

% 绘制堆叠面积图
area_handles = area(time_plot, wave_percentages_time);
for i = 1:length(wave_names)
    if ischar(wave_colors{i}) && strcmp(wave_colors{i}, 'k')
        area_handles(i).FaceColor = [0, 0, 0];
    elseif ischar(wave_colors{i}) && strcmp(wave_colors{i}, 'b')
        area_handles(i).FaceColor = [0, 0, 1];
    elseif ischar(wave_colors{i}) && strcmp(wave_colors{i}, 'r')
        area_handles(i).FaceColor = [1, 0, 0];
    else
        area_handles(i).FaceColor = [0, 0.6, 0];
    end
    area_handles(i).FaceAlpha = 0.7;
end

xlim([min(time_plot), max(time_plot)]);
xticks(xt);
xticklabels(cellstr(datestr(xt, 'mm/dd')));
ylabel('Percentage of Cumulative Contribution (%)', 'FontSize', 11);
title('Percentage Contribution Over Time', 'FontSize', 12, 'FontWeight', 'bold');
legend(wave_names, 'Location', 'best', 'FontSize', 10);
grid on;
set(gca, 'FontSize', 10);
ylim([0, 100]);

sgtitle('Cumulative Wave Contributions Analysis', 'FontSize', 14, 'FontWeight', 'bold');
saveas(gcf, 'Precipitation_Cumulative_Contributions_6hourly.png');
fprintf('补充图4已保存为 Precipitation_Cumulative_Contributions_6hourly.png\n');