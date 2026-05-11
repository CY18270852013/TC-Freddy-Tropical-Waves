clear; clc;
input_path = 'E:\Results_of_Freddy\GPM_6hourly_20090101_20231231';
output_path = 'E:\Results_of_Freddy\GPM_anomaly_6hourly';

%% 步骤1: 计算15年平均值和标准化降水
fprintf('步骤1: 计算15年平均值和标准化降水(20°S~20°N)\n');
files = dir(fullfile(input_path, 'GPM_6hourly_*.nc'));
n_files_total = length(files);

% 筛选2009年1月1日到2023年12月31日的文件
selected_files = [];
file_dates = [];
for i = 1:n_files_total
    filename = files(i).name;
    % 从文件名中提取时间信息
    date_str = filename(13:26); % '20090101000000'
    file_date = datetime(date_str, 'InputFormat', 'yyyyMMddHHmmss');
    if file_date >= datetime(2009,1,1) && file_date <= datetime(2024,1,1)
        selected_files = [selected_files; files(i)];
        file_dates = [file_dates; file_date];
    end
end

% 按日期排序
[~, sort_idx] = sort(file_dates);
files = selected_files(sort_idx);
n_files = length(files);
fprintf('找到 %d 个符合日期范围的文件\n', n_files);

% 读取第一个文件获取维度信息
first_file = fullfile(input_path, files(1).name);
lon = ncread(first_file, 'lon');
lat = ncread(first_file, 'lat');
lat_min = -20;  % 20°S
lat_max = 20;   % 20°N
lat_indices = find(lat >= lat_min & lat <= lat_max);
lat_selected = lat(lat_indices);
nLat_selected = length(lat_indices);
nLon = length(lon);
fprintf('纬度范围: %.1f°S ~ %.1f°N, 共 %d 个纬度点\n', -lat_min, lat_max, nLat_selected);

% 初始化累加数组
total_precip = zeros(nLat_selected, nLon, "single");
valid_count = zeros(nLat_selected, nLon, 'single');
original_6hourly_precipitation = zeros(nLat_selected, nLon, n_files, 'single');

% 读取、累加计算平均值、保存原始数据
for i = 1:n_files
    filename = fullfile(input_path, files(i).name);
    precip_full = ncread(filename, 'precipitation');
    precip = precip_full(lat_indices, :);
    original_6hourly_precipitation(:, :, i) = precip;
    
    % 处理缺失值并累加计算平均值
    valid_mask = (precip ~= -9999.9004);
    precip_for_sum = precip;
    precip_for_sum(~valid_mask) = 0;
    total_precip = total_precip + precip_for_sum;
    valid_count = valid_count + single(valid_mask);
    
    if mod(i, 1000) == 0
        fprintf('  已处理 %d/%d 个文件...\n', i, n_files);
    end
end

% 计算15年平均值
mean_precip = zeros(nLat_selected, nLon, 'single');
non_zero_mask = (valid_count > 0);
mean_precip(non_zero_mask) = total_precip(non_zero_mask) ./ valid_count(non_zero_mask);
mean_precip(~non_zero_mask) = -9999.9004;

% 计算标准化降水
normalized_precip = zeros(nLat_selected, nLon, n_files, 'single');
for i = 1:n_files
    precip = original_6hourly_precipitation(:, :, i);
    current_normalized_precip = precip - mean_precip;
    original_missing = (precip == -9999.9004);
    mean_missing = (mean_precip == -9999.9004);
    current_normalized_precip(original_missing | mean_missing) = -9999.9004;
    normalized_precip(:, :, i) = current_normalized_precip;
end

% 保存中间结果
save(fullfile(output_path, 'mean_precip_20S_20N.mat'), 'mean_precip', 'lon', 'lat_selected', '-v7.3');
save(fullfile(output_path, 'normalized_precip_20S_20N.mat'), 'normalized_precip', 'lon', 'lat_selected', '-v7.3');
fprintf('步骤1完成: 15年平均和标准化降水计算并保存\n');

% 清理内存
clear total_precip valid_count precip_full precip precip_for_sum;

%% 步骤2: 计算气候态并进行傅里叶滤波
fprintf('步骤2: 计算气候态并进行傅里叶滤波 (20°S~20°N)...\n');

% 创建时间序列（6小时分辨率）
start_date = datetime(2009, 1, 1, 0, 0, 0);
end_date = datetime(2023, 12, 31, 18, 0, 0);
date_sequence = start_date:hours(6):end_date;

% 气候态使用365天×4个时次（6小时间隔）
climatology = zeros(nLat_selected, nLon, 365, 4, 'single'); % 600 × 3600 × 365 × 4
count = zeros(nLat_selected, nLon, 365, 4, 'single');

% 月份累积天数（非闰年）
cum_days = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];

for i = 1:length(date_sequence)
    current_date = date_sequence(i);
    year_val = year(current_date);
    month_val = month(current_date);
    day_val = day(current_date);
    hour_val = hour(current_date);
    
    % 确定时次索引 (0,6,12,18 -> 1,2,3,4)
    time_of_day_idx = floor(hour_val/6) + 1;
    
    % 跳过闰年的2月29日
    is_leap_year = (mod(year_val, 4) == 0 && mod(year_val, 100) ~= 0) || (mod(year_val, 400) == 0);
    is_feb_29 = (month_val == 2 && day_val == 29);
    if is_leap_year && is_feb_29
        continue;
    end
    
    % 计算年积日
    doy = cum_days(month_val) + day_val;
    
    precip = normalized_precip(:, :, i);
    precip_mask = (precip == -9999.9004);
    precip_nan = single(precip);
    precip_nan(precip_mask) = NaN;
    
    % 累加到对应年积日和时次
    for lat_idx = 1:nLat_selected
        for lon_idx = 1:nLon
            if ~isnan(precip_nan(lat_idx, lon_idx))
                climatology(lat_idx, lon_idx, doy, time_of_day_idx) = ...
                    climatology(lat_idx, lon_idx, doy, time_of_day_idx) + precip_nan(lat_idx, lon_idx);
                count(lat_idx, lon_idx, doy, time_of_day_idx) = ...
                    count(lat_idx, lon_idx, doy, time_of_day_idx) + 1;
            end
        end
    end
    
    if mod(i, 5000) == 0
        fprintf('  已处理 %d/%d 个时次数据计算气候态...\n', i, length(date_sequence));
    end
end

% 计算气候态平均值
valid_count_mask = (count > 0);
climatology(valid_count_mask) = climatology(valid_count_mask) ./ count(valid_count_mask);
climatology(~valid_count_mask) = -9999.9004;

% 将4维气候态转换为3维 (365×4 = 1460个时次)
climatology_3d = reshape(climatology, nLat_selected, nLon, []);
save(fullfile(output_path, 'climatology_20S_20N.mat'), 'climatology_3d', 'lon', 'lat_selected', '-v7.3');
fprintf('气候态计算完成，维度: %dx%dx%d\n', size(climatology_3d, 1), size(climatology_3d, 2), size(climatology_3d, 3));

clear count valid_count_mask precip_nan climatology;

%% 步骤3: 傅里叶滤波
fprintf('步骤3: 傅里叶滤波 (20°S~20°N)...\n');
[nLat_sel, nLon_sel, nTime_clim] = size(climatology_3d); % 600 × 3600 × 1460
fit_climatology = zeros(size(climatology_3d));

for i = 1:nLat_sel
    for j = 1:nLon_sel
        time_series = squeeze(climatology_3d(i, j, :));
        if all(time_series == -9999.9004)
            fit_climatology(i, j, :) = -9999.9004;
            continue;
        end
        
        % 傅里叶变换
        fft_series = fft(time_series);
        % 保留前三阶谐波（前4个和后3个系数）
        fft_series(5:end-3) = 0;
        % 逆傅里叶变换
        fit_series = real(ifft(fft_series));
        fit_climatology(i, j, :) = fit_series;
    end
    
    if mod(i, 50) == 0
        fprintf('  已处理 %d/%d 个纬度...\n', i, nLat_sel);
    end
end

save(fullfile(output_path, 'fit_climatology_20S_20N.mat'), 'fit_climatology', 'lon', 'lat_selected', '-v7.3');
fprintf('傅里叶滤波完成\n');

clear climatology_3d fft_series;

%% 步骤4: 计算最终异常值并保存
fprintf('步骤4: 计算最终异常值 (20°S~20°N)...\n');

% 目标时间段：2022年9月1日到2023年6月30日
target_start_date = datetime(2022, 9, 1, 0, 0, 0);
target_end_date = datetime(2023, 6, 30, 18, 0, 0);

% 找到目标时间段在完整序列中的索引
start_idx = find(date_sequence >= target_start_date, 1);
end_idx = find(date_sequence <= target_end_date, 1, 'last');

subset_normalized_precip = normalized_precip(:, :, start_idx:end_idx);
nTime_target = size(subset_normalized_precip, 3);

fprintf('开始处理 %d 个时次的异常值计算 (20°S~20°N)...\n', nTime_target);
fprintf('数据时间范围: %s 到 %s\n', datestr(target_start_date), datestr(target_end_date));

target_dates = date_sequence(start_idx:end_idx);
anomaly_data = zeros(nLat_selected, nLon, nTime_target, 'single');
time_values = zeros(nTime_target, 1);

for i = 1:nTime_target
    current_date = target_dates(i);
    time_values(i) = datenum(current_date);
    
    year_val = year(current_date);
    month_val = month(current_date);
    day_val = day(current_date);
    hour_val = hour(current_date);
    
    % 计算年积日和时次索引
    time_of_day_idx = floor(hour_val/6) + 1;
    doy = cum_days(month_val) + day_val;
    
    % 在气候态中的索引 (365天×4时次)
    clim_index = (doy-1)*4 + time_of_day_idx;
    
    % 计算异常值
    normalized_precip_current = subset_normalized_precip(:, :, i);
    climate_value = fit_climatology(:, :, clim_index);
    anomaly = normalized_precip_current - climate_value;
    
    missing_mask = (normalized_precip_current == -9999.9004) | (climate_value == -9999.9004);
    anomaly(missing_mask) = -9999.9004;
    anomaly_data(:, :, i) = anomaly;
    
    if mod(i, 500) == 0
        fprintf('  已处理 %d/%d 个时次...\n', i, nTime_target);
    end
end

% 保存异常值数据
save(fullfile(output_path, 'anomaly_data_20S_20N.mat'), 'anomaly_data', 'lon', 'lat_selected', 'time_values', '-v7.3');
fprintf('异常值数据已保存\n');

% 创建并保存NetCDF文件
anomaly_file = fullfile(output_path, 'GPM_anomaly_6hourly_20220901_20230630.nc');

% 删除已存在的文件
if exist(anomaly_file, 'file')
    delete(anomaly_file);
end

% 创建NetCDF文件
nccreate(anomaly_file, 'precipitation_anomaly', ...
         'Dimensions', {'lat', nLat_selected, 'lon', nLon, 'time', nTime_target}, ...
         'Datatype', 'single', ...
         'FillValue', -9999.9004);
nccreate(anomaly_file, 'lon', 'Dimensions', {'lon', nLon}, 'Datatype', 'single');
nccreate(anomaly_file, 'lat', 'Dimensions', {'lat', nLat_selected}, 'Datatype', 'single');
nccreate(anomaly_file, 'time', 'Dimensions', {'time', nTime_target}, 'Datatype', 'double');

% 写入数据
ncwrite(anomaly_file, 'lon', lon);
ncwrite(anomaly_file, 'lat', lat_selected);
ncwrite(anomaly_file, 'precipitation_anomaly', anomaly_data);
ncwrite(anomaly_file, 'time', time_values);

% 添加全局属性
ncwriteatt(anomaly_file, '/', 'title', 'GPM 6-hourly Precipitation Anomaly (20S-20N)');
ncwriteatt(anomaly_file, '/', 'source', 'GPM IMERG Half-Hourly Data');
ncwriteatt(anomaly_file, '/', 'date_created', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
ncwriteatt(anomaly_file, '/', 'latitude_range', '20S to 20N');
ncwriteatt(anomaly_file, '/', 'time_coverage_start', '20220901T00:00:00Z');
ncwriteatt(anomaly_file, '/', 'time_coverage_end', '20230630T18:00:00Z');
ncwriteatt(anomaly_file, '/', 'temporal_resolution', '6 hours');
ncwriteatt(anomaly_file, '/', 'spatial_resolution', '0.1 degree');
ncwriteatt(anomaly_file, '/', 'units', 'mm');
ncwriteatt(anomaly_file, '/', 'long_name', '6-hourly precipitation anomaly');
ncwriteatt(anomaly_file, '/', 'method', '15-year mean removed + FFT filtering (first 3 harmonics)');

fprintf('异常值文件保存完成: %s\n', anomaly_file);
fprintf('所有处理完成！纬度范围: 20°S ~ 20°N, 时间范围: 2022-09-01 到 2023-06-30\n');

% 清理内存
clear normalized_precip original_6hourly_precipitation subset_normalized_precip fit_climatology anomaly_data;