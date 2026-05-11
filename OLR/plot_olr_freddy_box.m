%% 清空环境
clear; clc; close all;

%% 文件路径设置
data_path = 'E:\Results_of_Freddy\olr_daily\';

files = {
    fullfile(data_path, 'olr_anomaly_daily_20220101_20231231.nc');          % 原始OLR异常
    fullfile(data_path, 'olr_anomaly_for_MJO_daily_20220101_20231231.nc');  % MJO滤波
    fullfile(data_path, 'olr_anomaly_for_Kelvin_daily_20220101_20231231.nc'); % Kelvin滤波
    fullfile(data_path, 'olr_anomaly_for_MRG_daily_20220101_20231231.nc');   % MRG滤波
    fullfile(data_path, 'olr_anomaly_for_ER_daily_20220101_20231231.nc');    % ER滤波
};

%% 区域设置
lon_range = [110, 120];  % 东经110-120°
lat_range = [-20, -10];  % 南纬10-20°

% 使用datetime格式的时间
date_start = datetime('2023-02-01');
date_end = datetime('2023-02-12');

%% 读取原始OLR异常数据（纬度范围-90~90）
fprintf('读取原始OLR异常数据...\n');
time_raw = ncread(files{1}, 'time');
% 将时间从days since 1970-01-01转换为datetime
time_dates = datetime(1970,1,1) + days(time_raw);
time_idx = time_dates >= date_start & time_dates <= date_end;
time_plot = time_dates(time_idx);
time_count = sum(time_idx);

% 读取完整的原始数据
lat_all = ncread(files{1}, 'lat');
lon_all = ncread(files{1}, 'lon');
olr_all = ncread(files{1}, 'olr_anomaly_daily');

% 选择时间维度的数据
olr_all_time = olr_all(:,:,time_idx);

% 创建纬度和经度的网格
[LON, LAT] = meshgrid(lon_all, lat_all);

% 创建区域掩膜
region_mask = (LON >= lon_range(1) & LON <= lon_range(2) & ...
               LAT >= lat_range(1) & LAT <= lat_range(2));

% 计算区域平均时间序列
olr_region_mean = zeros(time_count, 1);
for t = 1:time_count
    olr_slice = olr_all_time(:,:,t);
    % 应用掩膜并计算平均
    region_values = olr_slice(region_mask);
    olr_region_mean(t) = mean(region_values(~isnan(region_values)));
end
fprintf('原始OLR数据处理完成\n');

%% 读取各滤波后的OLR异常数据
wave_names = {'MJO', 'Kelvin', 'MRG', 'ER'};
wave_colors = {'k', 'b', [0, 0.6, 0], 'r'}; % 黑、蓝、绿、红
olr_waves = zeros(time_count, length(wave_names));

for i = 1:length(wave_names)
    fprintf('读取%s波数据...\n', wave_names{i});
    file = files{i+1};
    
    % 读取完整的滤波后数据
    lat_wave = ncread(file, 'lat');
    lon_wave = ncread(file, 'lon');
    
    % 动态确定变量名
    var_names = ncinfo(file).Variables;
    var_name_list = {var_names.Name};
    
    % 寻找合适的变量名
    target_var = '';
    for j = 1:length(var_name_list)
        if contains(var_name_list{j}, wave_names{i}, 'IgnoreCase', true) || ...
           contains(var_name_list{j}, lower(wave_names{i}), 'IgnoreCase', true)
            target_var = var_name_list{j};
            break;
        end
    end
    
    if isempty(target_var)
        % 如果没找到，尝试使用默认名称
        target_var = sprintf('olr_anomaly_%s', lower(wave_names{i}));
    end
    
    % 读取完整数据
    olr_wave_all = ncread(file, target_var);
    
    % 选择时间维度的数据
    olr_wave_time = olr_wave_all(:,:,time_idx);
    
    % 创建纬度和经度的网格
    [LON_WAVE, LAT_WAVE] = meshgrid(lon_wave, lat_wave);
    
    % 创建区域掩膜
    region_mask_wave = (LON_WAVE >= lon_range(1) & LON_WAVE <= lon_range(2) & ...
                       LAT_WAVE >= lat_range(1) & LAT_WAVE <= lat_range(2));
    
    % 计算区域平均时间序列
    for t = 1:time_count
        olr_wave_slice = olr_wave_time(:,:,t);
        % 应用掩膜并计算平均
        region_values_wave = olr_wave_slice(region_mask_wave);
        olr_waves(t, i) = mean(region_values_wave(~isnan(region_values_wave)));
    end
    fprintf('%s波数据处理完成\n', wave_names{i});
end

%% 计算所有波动的总和
olr_sum = sum(olr_waves, 2);

%% 绘制时间序列图
figure('Position', [100, 100, 900, 500], 'Color', 'white');

% 绘制各波动分量
hold on;
for i = 1:length(wave_names)
    plot(time_plot, olr_waves(:, i), 'Color', wave_colors{i}, 'LineWidth', 1.5, 'DisplayName', wave_names{i});
end

% 绘制总和
plot(time_plot, olr_sum, 'Color', [0.5, 0, 0.8], 'LineWidth', 2, 'DisplayName', 'Sum of All Waves');

% 绘制原始OLR异常
plot(time_plot, olr_region_mean, '--', 'Color', 'k', 'LineWidth', 2, 'DisplayName', 'OLR Anomaly');

hold off;

%% 设置图形属性
xlim([date_start, date_end]);
xt = date_start:days(2):date_end;
xticks(xt);
xticklabels(datestr(xt, 'mm/dd'));
xlabel('Date (2023)', 'FontSize', 12);

ylabel('OLR Anomaly (W m^{-2})', 'FontSize', 12);
title('OLR Anomaly Contributions in Freddy Genesis Box (110°E-120°E, 10°S-20°S)', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 10);
grid on;
set(gca, 'FontSize', 11, 'Box', 'on');

%% 调整纵轴范围
all_data = [olr_region_mean; olr_sum; olr_waves(:)];
all_data_valid = all_data(~isnan(all_data));
if ~isempty(all_data_valid)
    y_min = min(all_data_valid) - 10;
    y_max = max(all_data_valid) + 10;
    ylim([y_min, y_max]);
else
    warning('所有数据都是NaN，请检查数据质量');
end

%% 添加参考线
hold on;
plot([date_start, date_end], [0, 0], 'k--', 'LineWidth', 0.5, 'HandleVisibility', 'off');
hold off;

%% 保存图片
saveas(gcf, 'Freddy_Genesis_OLR_Anomaly_Contributions.png');
disp('图片已保存为 Freddy_Genesis_OLR_Anomaly_Contributions.png');

%% 显示数据统计信息
fprintf('\n数据统计信息:\n');
fprintf('时间范围: %s 到 %s\n', datestr(date_start), datestr(date_end));
fprintf('数据点数: %d\n', length(time_plot));
fprintf('区域范围: 经度 %.1f°E-%.1f°E, 纬度 %.1f°S-%.1f°S\n', ...
    lon_range(1), lon_range(2), -lat_range(1), -lat_range(2));
fprintf('OLR异常范围: [%.2f, %.2f] W/m²\n', min(olr_region_mean), max(olr_region_mean));
fprintf('各波列贡献范围:\n');
for i = 1:length(wave_names)
    if ~all(isnan(olr_waves(:, i)))
        fprintf('  %s: [%.2f, %.2f] W/m²\n', wave_names{i}, ...
            min(olr_waves(:, i)), max(olr_waves(:, i)));
    else
        fprintf('  %s: 所有数据都是NaN\n', wave_names{i});
    end
end

%% 保存数据到MAT文件
save('Freddy_OLR_Data.mat', 'time_plot', 'olr_region_mean', 'olr_waves', ...
    'olr_sum', 'wave_names', 'lon_range', 'lat_range');
fprintf('数据已保存到 Freddy_OLR_Data.mat\n');












%% 创建补充图1：分开展示各分量
figure('Position', [100, 100, 1200, 800], 'Color', 'white');

% 创建子图：原始异常和总和
subplot(3, 2, 1);
plot(time_plot, olr_region_mean, '--', 'Color', 'k', 'LineWidth', 2);
xlim([min(time_plot), max(time_plot)]);
xticks(xt);
xticklabels(cellstr(datestr(xt, 'mm/dd')));
ylabel('W m^{-2}', 'FontSize', 10);
title('Total OLR Anomaly', 'FontSize', 11, 'FontWeight', 'bold');
grid on;
set(gca, 'FontSize', 9);

% 各波列分量子图
for i = 1:length(wave_names)
    subplot(3, 2, i+1);
    plot(time_plot, olr_waves(:, i), 'Color', wave_colors{i}, 'LineWidth', 1.5);
    xlim([min(time_plot), max(time_plot)]);
    xticks(xt);
    xticklabels(cellstr(datestr(xt, 'mm/dd')));
    ylabel('W m^{-2}', 'FontSize', 10);
    title(sprintf('%s Wave Contribution', wave_names{i}), 'FontSize', 11, 'FontWeight', 'bold');
    grid on;
    set(gca, 'FontSize', 9);
end

% 总和子图
subplot(3, 2, 6);
plot(time_plot, olr_sum, 'Color', [0.5, 0, 0.8], 'LineWidth', 2);
xlim([min(time_plot), max(time_plot)]);
xticks(xt);
xticklabels(cellstr(datestr(xt, 'mm/dd')));
ylabel('W m^{-2}', 'FontSize', 10);
title('Sum of All Wave Contributions', 'FontSize', 11, 'FontWeight', 'bold');
grid on;
set(gca, 'FontSize', 9);

sgtitle('OLR Anomaly Contributions in Freddy Genesis Box (110°E-120°E, 10°S-20°S)', ...
    'FontSize', 14, 'FontWeight', 'bold');

% 调整纵轴范围保持一致
subplot_handles = findobj(gcf, 'Type', 'axes');
all_olr_data = [olr_region_mean; olr_sum; olr_waves(:)];
all_olr_data_valid = all_olr_data(~isnan(all_olr_data));
if ~isempty(all_olr_data_valid)
    y_min = min(all_olr_data_valid) - 5;
    y_max = max(all_olr_data_valid) + 5;
    for i = 1:length(subplot_handles)
        subplot(subplot_handles(i));
        ylim([y_min, y_max]);
    end
end

% 添加零线
for i = 1:length(subplot_handles)
    subplot(subplot_handles(i));
    hold on;
    plot([min(time_plot), max(time_plot)], [0, 0], 'k--', 'LineWidth', 0.5);
    hold off;
end

saveas(gcf, 'OLR_Contributions_Subplots.png');
fprintf('补充图1已保存为 OLR_Contributions_Subplots.png\n');

%% 创建补充图2：各波列相对贡献比例
figure('Position', [100, 100, 800, 400], 'Color', 'white');

% 计算各波列在整个时段内的平均贡献（取绝对值）
wave_means = zeros(1, length(wave_names));
for i = 1:length(wave_names)
    valid_data = olr_waves(:, i);
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
    title('Relative Contribution of Different Waves to OLR Anomaly', ...
        'FontSize', 13, 'FontWeight', 'bold');
    set(gca, 'XTick', 1:length(wave_names), 'XTickLabel', wave_names, 'FontSize', 11);
    grid on;
    ylim([0, max(wave_percentages) * 1.2]);
    
    saveas(gcf, 'OLR_Wave_Contribution_Percentages.png');
    fprintf('补充图2已保存为 OLR_Wave_Contribution_Percentages.png\n');
else
    fprintf('无法计算波列贡献比例：总贡献为零\n');
end

%% 创建补充图3：散点图对比原始OLR与波列总和
figure('Position', [100, 100, 800, 600], 'Color', 'white');

% 移除NaN值
valid_idx = ~isnan(olr_region_mean) & ~isnan(olr_sum);
olr_region_valid = olr_region_mean(valid_idx);
olr_sum_valid = olr_sum(valid_idx);

if length(olr_region_valid) > 1
    % 散点图
    scatter(olr_region_valid, olr_sum_valid, 50, 'filled', 'MarkerFaceColor', [0.2, 0.4, 0.8], ...
        'MarkerEdgeColor', 'k', 'LineWidth', 1);
    
    % 添加回归线
    hold on;
    p = polyfit(olr_region_valid, olr_sum_valid, 1);
    x_fit = [min(olr_region_valid), max(olr_region_valid)];
    y_fit = polyval(p, x_fit);
    plot(x_fit, y_fit, 'r-', 'LineWidth', 2);
    
    % 添加1:1参考线
    plot([min(olr_region_valid), max(olr_region_valid)], ...
         [min(olr_region_valid), max(olr_region_valid)], 'k--', 'LineWidth', 1.5);
    hold off;
    
    % 计算相关系数和RMSE
    corr_coef = corr(olr_region_valid, olr_sum_valid);
    rmse = sqrt(mean((olr_region_valid - olr_sum_valid).^2));
    
    % 添加统计信息文本
    text(0.05, 0.95, sprintf('Correlation: %.3f', corr_coef), ...
        'Units', 'normalized', 'FontSize', 11, 'FontWeight', 'bold', ...
        'BackgroundColor', 'white');
    text(0.05, 0.88, sprintf('RMSE: %.2f W/m²', rmse), ...
        'Units', 'normalized', 'FontSize', 11, 'FontWeight', 'bold', ...
        'BackgroundColor', 'white');
    text(0.05, 0.81, sprintf('Slope: %.3f', p(1)), ...
        'Units', 'normalized', 'FontSize', 11, 'FontWeight', 'bold', ...
        'BackgroundColor', 'white');
    text(0.05, 0.74, sprintf('Intercept: %.3f', p(2)), ...
        'Units', 'normalized', 'FontSize', 11, 'FontWeight', 'bold', ...
        'BackgroundColor', 'white');
    
    xlabel('Original OLR Anomaly (W m^{-2})', 'FontSize', 12);
    ylabel('Sum of Wave Contributions (W m^{-2})', 'FontSize', 12);
    title('Comparison: Original OLR vs Wave Sum', 'FontSize', 13, 'FontWeight', 'bold');
    legend({'Data Points', 'Regression Line', '1:1 Line'}, 'Location', 'best', 'FontSize', 10);
    grid on;
    axis equal;
    
    % 设置相同的坐标范围
    all_values = [olr_region_valid; olr_sum_valid];
    lim_min = min(all_values) - 5;
    lim_max = max(all_values) + 5;
    xlim([lim_min, lim_max]);
    ylim([lim_min, lim_max]);
    
    saveas(gcf, 'OLR_Comparison_Scatter.png');
    fprintf('补充图3已保存为 OLR_Comparison_Scatter.png\n');
else
    fprintf('无法创建散点图：有效数据点不足\n');
end

%% 创建补充图4：各波列贡献的时间演变（堆叠面积图）
figure('Position', [100, 100, 900, 500], 'Color', 'white');

% 准备堆叠数据
stack_data = zeros(length(time_plot), length(wave_names));
for i = 1:length(wave_names)
    if i == 1
        stack_data(:, i) = olr_waves(:, i);
    else
        stack_data(:, i) = stack_data(:, i-1) + olr_waves(:, i);
    end
end

% 绘制堆叠面积图
hold on;
area_handles = zeros(1, length(wave_names)); % 存储面积图句柄

% 注意：绘制顺序应该从底层到顶层（先绘制最底层的）
for i = 1:length(wave_names)
    if i == 1
        area_handles(i) = area(time_plot, stack_data(:, i), 'FaceColor', wave_colors{i}, ...
            'EdgeColor', 'none', 'FaceAlpha', 0.8);
    else
        area_handles(i) = area(time_plot, stack_data(:, i), 'FaceColor', wave_colors{i}, ...
            'EdgeColor', 'none', 'FaceAlpha', 0.8);
    end
end

% 添加原始OLR异常作为黑色线
h_line = plot(time_plot, olr_region_mean, 'k-', 'LineWidth', 2.5);

% 添加零线
plot([min(time_plot), max(time_plot)], [0, 0], 'k--', 'LineWidth', 1);

hold off;

% 设置图形属性
xlim([min(time_plot), max(time_plot)]);
xticks(xt);
xticklabels(cellstr(datestr(xt, 'mm/dd')));
xlabel('Date (2023)', 'FontSize', 12);
ylabel('OLR Anomaly (W m^{-2})', 'FontSize', 12);
title('Stacked Wave Contributions to OLR Anomaly', 'FontSize', 13, 'FontWeight', 'bold');

% 创建正确的图例句柄数组和名称数组
legend_handles = [area_handles, h_line];
legend_names = [wave_names, {'Original OLR'}];

% 使用正确的句柄和名称创建图例
legend(legend_handles, legend_names, 'Location', 'best', 'FontSize', 10);

grid on;
set(gca, 'FontSize', 11, 'Box', 'on');

% 调整纵轴范围
all_data = [olr_region_mean; stack_data(:)];
all_data_valid = all_data(~isnan(all_data));
if ~isempty(all_data_valid)
    y_min = min(all_data_valid) - 10;
    y_max = max(all_data_valid) + 10;
    ylim([y_min, y_max]);
end

saveas(gcf, 'OLR_Stacked_Contributions.png');
fprintf('补充图4已保存为 OLR_Stacked_Contributions.png\n');

%% 输出最终统计信息
fprintf('\n=== 补充图生成完成 ===\n');
fprintf('已生成以下补充图：\n');
fprintf('1. OLR_Contributions_Subplots.png - 各分量分开展示\n');
fprintf('2. OLR_Wave_Contribution_Percentages.png - 波列贡献比例\n');
fprintf('3. OLR_Comparison_Scatter.png - 原始与总和对比\n');
fprintf('4. OLR_Stacked_Contributions.png - 堆叠贡献图\n');
fprintf('总计生成5张图（含主图）\n');