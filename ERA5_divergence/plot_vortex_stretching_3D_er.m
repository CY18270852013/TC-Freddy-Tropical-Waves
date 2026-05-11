%% 绘制Freddy生成期间ER对涡旋拉伸贡献的三维立体图
% 使用三维曲面展示涡旋拉伸项的空间分布
clear; clc; close all;

%% 1. 设置路径和参数
% 数据路径
er_div_file = 'E:\Results_of_Freddy\divergence_anomaly_6hourly\divergence_anomaly_for_ER_6hourly_20220101_20231231.nc';
era5_files = {
    'E:\Original_Data_of_Freddy\ERA5_dv_q_uv_200901_202312_every_6hours\202301_dv.nc';
    'E:\Original_Data_of_Freddy\ERA5_dv_q_uv_200901_202312_every_6hours\202302_dv.nc';
    'E:\Original_Data_of_Freddy\ERA5_dv_q_uv_200901_202312_every_6hours\202303_dv.nc'
};
ibtracs_file = 'E:\Original_Data_of_Freddy\IBTrACS.SI.v04r01.nc';

% Freddy的SID
freddy_sid = '2023036S12117';

% 研究时间段 (2023年2月4日-10日，每天12:00 UTC)
target_dates = datetime(2023, 2, [4:10]', 'TimeZone', 'UTC');
target_times = target_dates + hours(12); % 12:00 UTC

% Freddy genesis box (经度110-120°E，纬度10-20°S)
genesis_box = struct(...
    'lon_min', 110, ...
    'lon_max', 120, ...
    'lat_min', -20, ...
    'lat_max', -10);

% 显示区域
plot_extent = [100, 130, -25, -5]; % [lon_min, lon_max, lat_min, lat_max]

% 科里奥利参数 (Ω)
omega = 7.2921159e-5; % rad/s

% 输出设置
output_dir = 'er_vortex_stretching_3d';
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

%% 2. 读取和处理IBTrACS数据，获取Freddy路径
fprintf('=== 读取IBTrACS数据 ===\n');

% 读取IBTrACS变量
sid_data = ncread(ibtracs_file, 'sid'); % 13x2854
season_data = ncread(ibtracs_file, 'season'); % 2854x1
time_data = ncread(ibtracs_file, 'time'); % 360x2854 (days since 1858-11-17)
lat_data = ncread(ibtracs_file, 'lat'); % 360x2854
lon_data = ncread(ibtracs_file, 'lon'); % 360x2854

% 找到Freddy
freddy_idx = -1;
for i = 1:size(sid_data, 2)
    sid_str = char(sid_data(:, i)');
    if strtrim(sid_str) == freddy_sid
        freddy_idx = i;
        fprintf('找到Freddy: SID=%s, 年份=%d\n', sid_str, season_data(i));
        break;
    end
end

if freddy_idx == -1
    error('未找到SID为%s的热带气旋', freddy_sid);
end

% 提取Freddy的路径数据
freddy_time_raw = time_data(:, freddy_idx); % days since 1858-11-17
freddy_lat_raw = lat_data(:, freddy_idx);
freddy_lon_raw = lon_data(:, freddy_idx);

% 转换时间 (从1858-11-17到MATLAB datetime)
base_date = datetime(1858, 11, 17, 'TimeZone', 'UTC');
freddy_time = base_date + days(freddy_time_raw);

% 移除无效数据 (FillValue = -9999)
valid_idx = freddy_lat_raw > -9000 & freddy_lon_raw > -9000;
freddy_time = freddy_time(valid_idx);
freddy_lat = freddy_lat_raw(valid_idx);
freddy_lon = freddy_lon_raw(valid_idx);

% 获取Freddy在目标时刻的位置
freddy_positions = zeros(length(target_times), 2); % [lon, lat]
for i = 1:length(target_times)
    target_time = target_times(i);
    
    % 找到最接近的时间点
    [~, idx] = min(abs(freddy_time - target_time));
    time_diff = abs(freddy_time(idx) - target_time);
    
    if time_diff < hours(3)
        freddy_positions(i, :) = [freddy_lon(idx), freddy_lat(idx)];
    else
        % 线性插值
        time_diff_array = freddy_time - target_time;
        before_idx = find(time_diff_array < 0, 1, 'last');
        after_idx = find(time_diff_array > 0, 1, 'first');
        
        if ~isempty(before_idx) && ~isempty(after_idx)
            t1 = freddy_time(before_idx);
            t2 = freddy_time(after_idx);
            lon1 = freddy_lon(before_idx);
            lon2 = freddy_lon(after_idx);
            lat1 = freddy_lat(before_idx);
            lat2 = freddy_lat(after_idx);
            
            alpha = seconds(target_time - t1) / seconds(t2 - t1);
            freddy_positions(i, 1) = lon1 + alpha * (lon2 - lon1);
            freddy_positions(i, 2) = lat1 + alpha * (lat2 - lat1);
        else
            freddy_positions(i, :) = [freddy_lon(idx), freddy_lat(idx)];
        end
    end
    
    fprintf('目标时间: %s, Freddy位置: %.2f°E, %.2f°S\n', ...
        datestr(target_time), freddy_positions(i, 1), -freddy_positions(i, 2));
end

%% 3. 读取和处理ERA5数据，计算绝对涡度
fprintf('\n=== 处理ERA5数据 ===\n');

% 合并三个月的ERA5数据
era5_time_all = [];
era5_lat_all = [];
era5_lon_all = [];
era5_pres_all = [];
era5_vo_all = [];

for f = 1:length(era5_files)
    fprintf('读取文件: %s\n', era5_files{f});
    
    % 读取时间
    valid_time = ncread(era5_files{f}, 'valid_time');
    file_time = datetime(1970, 1, 1, 'TimeZone', 'UTC') + seconds(valid_time);
    
    % 读取纬度、经度、气压层
    file_lat = ncread(era5_files{f}, 'latitude');
    file_lon = ncread(era5_files{f}, 'longitude');
    file_pres = ncread(era5_files{f}, 'pressure_level');
    
    % 读取相对涡度
    file_vo = ncread(era5_files{f}, 'vo');
    
    % 如果是第一个文件，初始化数组
    if f == 1
        era5_lat_all = file_lat;
        era5_lon_all = file_lon;
        era5_pres_all = file_pres;
    end
    
    % 合并时间序列
    era5_time_all = [era5_time_all; file_time];
    
    % 合并涡度数据
    if f == 1
        era5_vo_all = file_vo;
    else
        era5_vo_all = cat(4, era5_vo_all, file_vo);
    end
end

% 检查数据维度
fprintf('ERA5数据维度: 时间=%d, 纬度=%d, 经度=%d, 气压层=%d\n', ...
    length(era5_time_all), length(era5_lat_all), length(era5_lon_all), length(era5_pres_all));

% 找到850 hPa层对应的索引
[~, pres_idx_850] = min(abs(era5_pres_all - 850));
fprintf('850 hPa层索引: %d (%.1f hPa)\n', pres_idx_850, era5_pres_all(pres_idx_850));

% 提取850 hPa的相对涡度
vo_850 = squeeze(era5_vo_all(:, :, pres_idx_850, :)); % lon×lat×time

% ERA5数据纬度是降序排列的(10°N到30°S)，需要反转使其升序
era5_lat_sorted = flipud(era5_lat_all); % 现在是从-30到10

% 调整经度：从0-360转换为-180-180格式
era5_lon_adj = era5_lon_all;
era5_lon_adj(era5_lon_adj > 180) = era5_lon_adj(era5_lon_adj > 180) - 360;
[era5_lon_sorted, lon_sort_idx] = sort(era5_lon_adj);

% 重新排列vo_850数据以匹配排序后的纬度和经度
vo_850_sorted = zeros(size(vo_850));
for t = 1:size(vo_850, 3)
    temp = flip(vo_850(:, :, t), 2); % 反转纬度维度
    vo_850_sorted(:, :, t) = temp(lon_sort_idx, :);
end

%% 4. 读取和处理ER散度异常数据
fprintf('\n=== 处理ER散度异常数据 ===\n');

% 读取ER散度数据
er_time_raw = ncread(er_div_file, 'time'); % days since 0000-01-01
er_lat = ncread(er_div_file, 'latitude');
er_lon = ncread(er_div_file, 'longitude');
er_div = ncread(er_div_file, 'divergence_anomaly_er'); % s^-1

% 转换时间
base_date2 = datetime(0, 1, 1, 'TimeZone', 'UTC');
er_time = base_date2 + days(er_time_raw) - days(1);

fprintf('ER数据维度: 时间=%d, 纬度=%d, 经度=%d\n', ...
    length(er_time), length(er_lat), length(er_lon));

% 同样处理ER数据的网格
er_lat_sorted = flipud(er_lat); % 从-30到10

% 调整经度格式并排序
er_lon_adj = er_lon;
er_lon_adj(er_lon_adj > 180) = er_lon_adj(er_lon_adj > 180) - 360;
[er_lon_sorted, er_lon_sort_idx] = sort(er_lon_adj);

% 重新排列er_div数据
er_div_sorted = zeros(size(er_div));
for t = 1:size(er_div, 3)
    temp = flip(er_div(:, :, t), 2); % 反转纬度维度
    er_div_sorted(:, :, t) = temp(er_lon_sort_idx, :);
end

%% 5. 为每个目标时间点计算和绘图
fprintf('\n=== 开始绘图 ===\n');

% 创建增强的蓝-白-红颜色映射
enhanced_blue_red = [
    0, 0, 0.8;      % 深蓝色
    0.2, 0.2, 1;    % 蓝色
    0.6, 0.6, 1;    % 浅蓝色
    1, 1, 1;        % 白色
    1, 0.6, 0.6;    % 浅红色
    1, 0.2, 0.2;    % 红色
    0.8, 0, 0       % 深红色
];

% 将颜色列表转换为颜色映射
cmap = interp1(linspace(0, 1, size(enhanced_blue_red, 1)), enhanced_blue_red, linspace(0, 1, 256));

% 加载海岸线数据
fprintf('加载海岸线数据...\n');
load coastlines;
coast_lon = coastlon;
coast_lat = coastlat;

% 为每个日期计算涡旋拉伸项
all_vortex_stretching = {};
all_lon_grid = {};
all_lat_grid = {};
valid_dates = {}; % 使用cell数组存储datetime对象

for t = 1:length(target_times)
    fprintf('\n处理时间点 %d/%d: %s\n', t, length(target_times), datestr(target_times(t)));
    
    target_time = target_times(t);
    
    % 从ERA5数据中找到最接近的时间索引
    [~, era5_time_idx] = min(abs(era5_time_all - target_time));
    era5_actual_time = era5_time_all(era5_time_idx);
    
    % 从ER数据中找到最接近的时间索引
    [~, er_time_idx] = min(abs(er_time - target_time));
    er_actual_time = er_time(er_time_idx);
    
    fprintf('  ERA5实际时间: %s (差%.1f小时)\n', datestr(era5_actual_time), ...
        hours(abs(era5_actual_time - target_time)));
    fprintf('  ER实际时间: %s (差%.1f小时)\n', datestr(er_actual_time), ...
        hours(abs(er_actual_time - target_time)));
    
    % 提取850 hPa相对涡度 (已排序)
    vo_850_slice = squeeze(vo_850_sorted(:, :, era5_time_idx)); % lon×lat
    
    % 提取ER散度异常 (已排序)
    div_er_slice = squeeze(er_div_sorted(:, :, er_time_idx)); % lon×lat
    
    % 创建统一网格并插值
    lon_grid = plot_extent(1):0.25:plot_extent(2);
    lat_grid = plot_extent(3):0.25:plot_extent(4);
    [LON, LAT] = meshgrid(lon_grid, lat_grid);
    
    % 插值相对涡度到统一网格
    vo_interp = interp2(era5_lon_sorted, era5_lat_sorted, vo_850_slice', LON, LAT, 'linear', 0);
    
    % 插值ER散度到统一网格
    div_er_interp = interp2(er_lon_sorted, er_lat_sorted, div_er_slice', LON, LAT, 'linear', 0);
    
    % 计算科里奥利参数 f = 2Ω sin(φ)
    f = 2 * omega * sind(LAT); % rad/s
    
    % 计算绝对涡度 (相对涡度 + f)
    abs_vorticity = vo_interp + f;
    
    % 计算涡旋拉伸项: abs_vorticity * div_er
    vortex_stretching = abs_vorticity .* (-div_er_interp);
    
    % 转换为(10^-9 s^-2)
    vortex_stretching_nano = vortex_stretching * 1e9;
    
    % 移除NaN值
    vortex_stretching_nano(isnan(vortex_stretching_nano)) = 0;
    
    % 存储数据
    all_vortex_stretching{end+1} = vortex_stretching_nano;
    all_lon_grid{end+1} = LON;
    all_lat_grid{end+1} = LAT;
    valid_dates{end+1} = target_time; % 使用cell数组存储
    
    fprintf('  成功计算涡旋拉伸项，数据形状: %dx%d\n', size(vortex_stretching_nano, 1), size(vortex_stretching_nano, 2));
end

% 确定全局色标范围 - 修复：只在循环结束后计算一次
all_data_combined = [];
for i = 1:length(all_vortex_stretching)
    all_data_combined = [all_data_combined; all_vortex_stretching{i}(:)];
end

if ~isempty(all_data_combined)
    valid_min = min(all_data_combined);
    valid_max = max(all_data_combined);
    abs_max = max(abs(valid_min), abs(valid_max));
    vmin = -abs_max;
    vmax = abs_max;
    
    fprintf('全局色标范围: %.2e 到 %.2e ×10^-9 s^-2\n', vmin, vmax);
else
    error('没有有效的涡旋拉伸项数据');
end

% 计算z_min (所有图中的最小值)
z_min_values = cellfun(@(x) min(x(:)), all_vortex_stretching);
z_min = min(z_min_values);
z_min_plane = z_min;

fprintf('z_min平面: %.2e ×10^-9 s^-2\n', z_min_plane);

% 确保vmin和vmax是标量
if ~isscalar(vmin) || ~isscalar(vmax)
    error('vmin和vmax必须是标量值');
end

%% 6. 绘制三维立体图
fprintf('\n=== 绘制三维立体图 ===\n');

for i = 1:length(valid_dates)
    fprintf('绘图 %d/%d: %s\n', i, length(valid_dates), datestr(valid_dates{i}));
    
    target_time = valid_dates{i};
    vortex_stretching_nano = all_vortex_stretching{i};
    LON = all_lon_grid{i};
    LAT = all_lat_grid{i};
    
    % 获取Freddy位置
    [~, time_idx] = ismember(target_time, target_times);
    freddy_lon = freddy_positions(time_idx, 1);
    freddy_lat = freddy_positions(time_idx, 2);
    
    % 如果经度超过180°，转换为-180到180格式
    if freddy_lon > 180
        freddy_lon = freddy_lon - 360;
    end
    
    % 创建三维图形
    fig = figure('Position', [100, 100, 1400, 700], 'Color', 'white');
    
    % 创建三维坐标轴
    ax = axes('Position', [0.08, 0.12, 0.75, 0.8]);
    
    % 创建三维曲面
    surf(LON, LAT, vortex_stretching_nano, ...
        'EdgeColor', 'k', ...      % 黑色网格线
        'LineWidth', 0.2, ...      % 细网格线
        'FaceAlpha', 0.95, ...     % 高透明度
        'FaceColor', 'interp');    % 插值颜色
    
    % 应用颜色映射
    colormap(cmap);
    
    % 检查vmin和vmax是否为有效标量
    if isscalar(vmin) && isscalar(vmax) && vmin < vmax
        caxis([vmin, vmax]);
    else
        % 如果全局范围无效，使用当前数据的范围
        data_min = min(vortex_stretching_nano(:));
        data_max = max(vortex_stretching_nano(:));
        caxis([data_min, data_max]);
        fprintf('  使用本地色标范围: %.2e 到 %.2e\n', data_min, data_max);
    end
    
    % 添加颜色条
    cb = colorbar('Location', 'eastoutside', 'Position', [0.85, 0.15, 0.02, 0.7]);
    cb.Label.String = 'Vortex Stretching (×10^{-9} s^{-2})';
    cb.Label.FontSize = 12;
    cb.Label.FontWeight = 'bold';
    
    % 设置三维视角 - 调整为更好的视角
    view([-35, 15]); % 调整视角以更好地显示三维结构
    
    % 设置坐标轴标签
    xlabel('Longitude (°E)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Latitude (°S)', 'FontSize', 12, 'FontWeight', 'bold');
    zlabel('Vortex Stretching (×10^{-9} s^{-2})', 'FontSize', 12, 'FontWeight', 'bold');
    
    % 设置坐标轴范围
    xlim([plot_extent(1), plot_extent(2)]);
    ylim([plot_extent(3), plot_extent(4)]);
    
    % 计算z轴范围
    z_abs_max = max(abs(vortex_stretching_nano(:)));
    zlim([z_min, z_abs_max]);
    
    % 设置网格
    grid on;
    box on;
    
    % 设置坐标轴刻度
    xticks(plot_extent(1):10:plot_extent(2));
    yticks(plot_extent(3):5:plot_extent(4));
    
    % 修改纬度轴标签为南纬表示
    yticklabels = get(gca, 'YTickLabel');
    ytick_numeric = zeros(size(yticklabels));
    for j = 1:length(yticklabels)
        yval = str2double(yticklabels{j});
        if ~isnan(yval)
            ytick_numeric(j) = yval;
        end
    end
    set(gca, 'YTickLabel', arrayfun(@(x) sprintf('%.0f°S', abs(x)), ytick_numeric, 'UniformOutput', false));
    
    % 设置经度轴标签
    xticklabels = get(gca, 'XTickLabel');
    xtick_numeric = zeros(size(xticklabels));
    for j = 1:length(xticklabels)
        xval = str2double(xticklabels{j});
        if ~isnan(xval)
            xtick_numeric(j) = xval;
        end
    end
    set(gca, 'XTickLabel', arrayfun(@(x) sprintf('%.0f°E', x), xtick_numeric, 'UniformOutput', false));
    
    % 设置z轴刻度
    z_ticks = linspace(z_min, z_abs_max, 5);
    set(gca, 'ZTick', z_ticks);
    z_tick_labels = arrayfun(@(x) sprintf('%.1f', x), z_ticks, 'UniformOutput', false);
    set(gca, 'ZTickLabel', z_tick_labels);
    
    % 添加标题
    title_str = sprintf('Vortex Stretching: ER Divergence × Absolute Vorticity\nDate: %s UTC | TC Freddy: %.2f°E, %.2f°S', ...
        datestr(target_time, 'yyyy-mm-dd HH:MM'), freddy_lon, abs(freddy_lat));
    title(title_str, 'FontSize', 14, 'FontWeight', 'bold');
    
    % ========== 添加地图底图在z_min平面 ==========
    hold on;
    
    % 绘制海岸线在z_min平面
    fprintf('  绘制海岸线...\n');
    
    % 只绘制在绘图区域内的海岸线
    coast_mask = coast_lon >= plot_extent(1) & coast_lon <= plot_extent(2) & ...
                 coast_lat >= plot_extent(3) & coast_lat <= plot_extent(4);
    
    if any(coast_mask)
        % 找到连续的线段
        coast_lon_masked = coast_lon(coast_mask);
        coast_lat_masked = coast_lat(coast_mask);
        
        % 绘制海岸线
        plot3(coast_lon_masked, coast_lat_masked, ones(size(coast_lon_masked)) * z_min_plane, ...
            'k-', 'LineWidth', 1.2);
    end
    
    % ========== 标记Freddy位置和Genesis Box在z_min平面 ==========
    % 标记Freddy涡旋位置
    plot3(freddy_lon, freddy_lat, z_min_plane, ...
        'ro', 'MarkerSize', 12, 'LineWidth', 2, 'MarkerFaceColor', 'r');
    
    % 添加Freddy标签
    text(freddy_lon, freddy_lat, z_min_plane, ' TC Freddy', ...
        'FontSize', 11, 'FontWeight', 'bold', 'Color', 'r', ...
        'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left');
    
    % 绘制Genesis Box在z_min平面
    box_lons = [genesis_box.lon_min, genesis_box.lon_max, genesis_box.lon_max, genesis_box.lon_min, genesis_box.lon_min];
    box_lats = [genesis_box.lat_min, genesis_box.lat_min, genesis_box.lat_max, genesis_box.lat_max, genesis_box.lat_min];
    
    plot3(box_lons, box_lats, ones(size(box_lons)) * z_min_plane, ...
        'Color', [1, 0.4, 0.6], 'LineWidth', 2.5, 'LineStyle', '-');
    
    % 添加Genesis Box标签
    text(mean([genesis_box.lon_min, genesis_box.lon_max]), ...
         mean([genesis_box.lat_min, genesis_box.lat_max]), ...
         z_min_plane, ' Freddy Genesis Box', ...
         'FontSize', 10, 'FontWeight', 'bold', 'Color', [1, 0.4, 0.6], ...
         'VerticalAlignment', 'middle', 'HorizontalAlignment', 'center');
    
    % ========== 保存图像 ==========
    filename = sprintf('freddy_vortex_stretching_3d_%s.png', ...
        datestr(target_time, 'yyyymmdd_HHMM'));
    output_path = fullfile(output_dir, filename);
    
    % 保存为高分辨率图像
    print(fig, output_path, '-dpng', '-r300');
    
    fprintf('  保存图像: %s\n', filename);
    
    % 关闭图形以释放内存
    close(fig);
end

%% 7. 生成汇总信息
fprintf('\n=== 处理完成 ===\n');
fprintf('图像已保存到目录: %s\n', output_dir);

% 创建汇总表格
summary_table = table(target_dates, freddy_positions(:,1), freddy_positions(:,2), ...
    'VariableNames', {'Date', 'Longitude_E', 'Latitude_S'});
disp('Freddy位置汇总:');
disp(summary_table);

% 保存位置数据到CSV文件
writetable(summary_table, fullfile(output_dir, 'freddy_positions_summary.csv'));

% 创建说明文件
info_file = fopen(fullfile(output_dir, 'README.txt'), 'w');
fprintf(info_file, '热带气旋Freddy生成期间ER对涡旋拉伸贡献的三维立体图\n');
fprintf(info_file, '生成时间: %s\n', datestr(now));
fprintf(info_file, '\n参数设置:\n');
fprintf(info_file, '  - Freddy SID: %s\n', freddy_sid);
fprintf(info_file, '  - 时间范围: 2023-02-04 12:00 UTC 到 2023-02-10 12:00 UTC\n');
fprintf(info_file, '  - Freddy生成区: %.0f-%.0f°E, %.0f-%.0f°S\n', ...
    genesis_box.lon_min, genesis_box.lon_max, abs(genesis_box.lat_min), abs(genesis_box.lat_max));
fprintf(info_file, '  - 显示区域: %.0f-%.0f°E, %.0f-%.0f°S\n', ...
    plot_extent(1), plot_extent(2), abs(plot_extent(3)), abs(plot_extent(4)));
fprintf(info_file, '\n计算方法:\n');
fprintf(info_file, '  1. 从ERA5提取850 hPa相对涡度\n');
fprintf(info_file, '  2. 计算绝对涡度: ζ_abs = ζ_rel + f (f=2Ωsinφ)\n');
fprintf(info_file, '  3. 从滤波数据提取ER散度异常\n');
fprintf(info_file, '  4. 计算涡旋拉伸: ζ_abs × div_ER\n');
fprintf(info_file, '  5. 单位转换: ×10^9 s^-2\n');
fprintf(info_file, '\n注意事项:\n');
fprintf(info_file, '  - 注意涡度符号: 在南半球，气旋性涡度为负值\n');
fprintf(info_file, '  - 注意散度符号: 负散度表示辐合，有利于气旋发展\n');
fprintf(info_file, '  - 涡旋拉伸项的正负表示对气旋发展的贡献\n');
fprintf(info_file, '\n文件说明:\n');
fprintf(info_file, '  - freddy_vortex_stretching_3d_*.png: 三维立体图\n');
fprintf(info_file, '  - freddy_positions_summary.csv: Freddy位置汇总\n');
fclose(info_file);

fprintf('\n所有处理完成！\n');