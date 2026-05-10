clear; clc;
input_path = '\\DS1821\Observation\GPM\daily';
output_path = 'E:\GPM_anomaly_daily';

%% 步骤1: 计算15年平均值和标准化降水
fprintf('步骤1: 计算15年平均值和标准化降水(30°S~30°N)\n');
files = dir(fullfile(input_path, '3B-DAY.MS.MRG.3IMERG.*-S000000-E235959.V07B.nc4'));
n_files_total = length(files);
% 筛选2009年1月1日到2023年12月31日的文件
selected_files = [];
file_dates = [];
for i = 1:n_files_total
    filename = files(i).name;
    % 位置22-29: YYYYMMDD
    date_str = filename(22:29);
    file_date = datetime(date_str, 'InputFormat', 'yyyyMMdd');
    if file_date >= datetime(2009,1,1) && file_date <= datetime(2023,12,31)
        selected_files = [selected_files; files(i)];
        file_dates = [file_dates; file_date];
    end
end
% 按日期排序
[~, sort_idx] = sort(file_dates);
files = selected_files(sort_idx);
n_files = length(files); % 5478
fprintf('找到 %d 个符合日期范围的文件\n', n_files);

first_file = fullfile(input_path, files(1).name);
lon = ncread(first_file, 'lon');
lat = ncread(first_file, 'lat');
lat_min = -30;  % 30°S
lat_max = 30;   % 30°N
lat_indices = find(lat >= lat_min & lat <= lat_max);
lat_selected = lat(lat_indices);
nLat_selected = length(lat_indices); % 600
nLon = length(lon); % nLon = 3600
fprintf('纬度范围: %.1f°S ~ %.1f°N, 共 %d 个纬度点\n', -lat_min, lat_max, nLat_selected);

total_precip = zeros(nLat_selected, nLon, "single"); % 600 * 3600
valid_count = zeros(nLat_selected, nLon, 'single'); % 600 * 3600
original_daily_precipitation = zeros(nLat_selected, nLon, n_files, 'single'); % 600 * 3600 * 5478
% 读取、累加计算平均值、保存原始数据
for i = 1:n_files
    filename = fullfile(input_path, files(i).name);
    precip_full = ncread(filename, 'precipitation'); % 1800 * 3600
    precip = precip_full(lat_indices, :);
    original_daily_precipitation(:, :, i) = precip;
    % 处理缺失值并累加计算平均值
    valid_mask = (precip ~= -9999.9004);
    precip_for_sum = precip;
    precip_for_sum(~valid_mask) = 0;
    total_precip = total_precip + precip_for_sum;
    valid_count = valid_count + single(valid_mask);
    if mod(i, 500) == 0
        fprintf('  已处理 %d/%d 个文件...\n', i, n_files);
    end
end
% 计算15年平均值
mean_precip = zeros(nLat_selected, nLon, 'single'); % 600 * 3600
non_zero_mask = (valid_count > 0);
mean_precip(non_zero_mask) = total_precip(non_zero_mask) ./ valid_count(non_zero_mask);
mean_precip(~non_zero_mask) = -9999.9004;

% 计算标准化降水
normalized_precip = zeros(nLat_selected, nLon, n_files, 'single'); % 600 * 3600 * 5478
for i = 1:n_files
    precip = original_daily_precipitation(:, :, i);
    current_normalized_precip = precip - mean_precip;
    original_missing = (precip == -9999.9004);
    mean_missing = (mean_precip == -9999.9004);
    current_normalized_precip(original_missing | mean_missing) = -9999.9004;
    normalized_precip(:, :, i) = current_normalized_precip;
end

save('mean_precip_30S_30N.mat', 'mean_precip', 'lon', 'lat_selected', '-v7.3');
save('original_daily_precipitation_30S_30N.mat', 'original_daily_precipitation', 'lon', 'lat_selected', '-v7.3');
save('normalized_precip_30S_30N.mat', 'normalized_precip', 'lon', 'lat_selected', '-v7.3');
fprintf('步骤1完成: 15年平均、原始日降水和标准化降水计算并保存\n');
% 清理不再需要的大变量
clear total_precip valid_count precip_full precip precip_for_sum;

%% 步骤2: 计算气候态并进行傅里叶滤波
fprintf('步骤2: 计算气候态并进行傅里叶滤波 (30°S~30°N)...\n');
start_date = datetime(2009, 1, 1);
end_date = datetime(2023, 12, 31);
date_sequence = start_date:end_date;
% 气候态使用365天
climatology = zeros(nLat_selected, nLon, 365, 'single'); % 600 * 3600 * 365
count = zeros(nLat_selected, nLon, 365, 'single'); % 600 * 3600 * 365
cum_days = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
for i = 1:length(date_sequence)
    current_date = date_sequence(i);
    year_val = year(current_date);
    month_val = month(current_date);
    day_val = day(current_date);
    % 如果是闰年的2月29日，跳过处理
    is_leap_year = (mod(year_val, 4) == 0 && mod(year_val, 100) ~= 0) || (mod(year_val, 400) == 0);
    is_feb_29 = (month_val == 2 && day_val == 29);
    if is_leap_year && is_feb_29
        continue;
    end
    doy = cum_days(month_val) + day_val;
    
    precip = normalized_precip(:, :, i);
    % 处理缺失值
    precip_mask = (precip == -9999.9004);
    precip_nan = single(precip);
    precip_nan(precip_mask) = NaN;
    % 累加到对应年积日
    for lat_idx = 1:nLat_selected
        for lon_idx = 1:nLon
            if ~isnan(precip_nan(lat_idx, lon_idx))
                climatology(lat_idx, lon_idx, doy) = climatology(lat_idx, lon_idx, doy) + precip_nan(lat_idx, lon_idx);
                count(lat_idx, lon_idx, doy) = count(lat_idx, lon_idx, doy) + 1;
            end
        end
    end
    if mod(i, 500) == 0
        fprintf('  已处理 %d/%d 天数据计算气候态...\n', i, length(date_sequence));
    end
end

% 计算气候态平均值
valid_count_mask = (count > 0);
climatology(valid_count_mask) = climatology(valid_count_mask) ./ count(valid_count_mask);
climatology(~valid_count_mask) = -9999.9004;
save('climatology_30S_30N.mat', 'climatology', 'lon', 'lat_selected', '-v7.3');
fprintf('气候态计算完成，维度: %dx%dx%d\n', size(climatology, 1), size(climatology, 2), size(climatology, 3));
clear count valid_count_mask precip_nan;

%% 步骤3: 傅里叶滤波
fprintf('步骤3: 傅里叶滤波 (30°S~30°N)...\n');
[nLat_sel, nLon_sel, nDays] = size(climatology); % 600 * 3600 * 365
fit_climatology = zeros(size(climatology));
for i = 1:nLat_sel
    for j = 1:nLon_sel
        time_series = squeeze(climatology(i, j, :));
        % 傅里叶变换
        fft_series = fft(time_series);
        fft_series(5:end - 3) = 0; % 保留直流分量, 前3个和后3个系数（对应前三阶谐波）
        % 逆傅里叶变换
        fit_series = real(ifft(fft_series));
        fit_climatology(i, j, :) = fit_series;
    end
end
save('fit_climatology_30S_30N.mat', 'fit_climatology', 'lon', 'lat_selected', '-v7.3');
fprintf('傅里叶滤波完成\n');
clear climatology fft_series filtered_fft;

%% 步骤4: 计算最终异常值并保存
fprintf('步骤4: 计算最终异常值 (30°S~30°N)...\n');
target_start_date = datetime(2022, 1, 1);
target_end_date = datetime(2023, 12, 31);
start_idx = days(target_start_date - start_date) + 1; % 4749
end_idx = days(target_end_date - start_date) + 1; % 5478
subset_normalized_precip = normalized_precip(:, :, start_idx:end_idx); % 600 * 3600 * 730
nTime = size(subset_normalized_precip, 3); % 730
fprintf('开始处理 %d 天的异常值计算 (30°S~30°N)...\n', nTime);
fprintf('数据时间范围: % 到 %\n', datestr(target_start_date), datestr(target_end_date));

target_dates = target_start_date:target_end_date;
anomaly_data = zeros(nLat_selected, nLon, nTime, 'single'); % 600 * 3600 * 730
time_values = zeros(nTime, 1); % 730 * 1
cum_days = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
for i = 1:nTime
    current_date = target_dates(i);
    date_num = datenum(current_date);
    time_values(i) = date_num;
    year_val = year(current_date);
    month_val = month(current_date);
    day_val = day(current_date);
    doy = cum_days(month_val) + day_val;
    % 计算异常值
    normalized_precip_current = subset_normalized_precip(:, :, i);
    climate_value = fit_climatology(:, :, doy);
    anomaly = normalized_precip_current - climate_value;
    missing_mask = (normalized_precip_current == -9999.9004) | (climate_value == -9999.9004);
    anomaly(missing_mask) = -9999.9004;
    anomaly_data(:, :, i) = anomaly;
end
save('anomaly_data_30S_30N.mat', 'anomaly_data', 'lon', 'lat_selected', 'time_values', '-v7.3');
fprintf('异常值数据已保存到 anomaly_data_30S_30N.mat\n');

% 创建并保存NetCDF文件
anomaly_file = fullfile(output_path, 'GPM_anomaly_daily_20220101_20231231_30S_30N.nc');
nccreate(anomaly_file, 'precipitation_anomaly', ...
         'Dimensions', {'lat', nLat_selected, 'lon', nLon, 'time', nTime}, ...
         'Datatype', 'single', ...
         'FillValue', -9999.9004);
nccreate(anomaly_file, 'lon', 'Dimensions', {'lon', nLon}, 'Datatype', 'single');
nccreate(anomaly_file, 'lat', 'Dimensions', {'lat', nLat_selected}, 'Datatype', 'single');
nccreate(anomaly_file, 'time', 'Dimensions', {'time', nTime}, 'Datatype', 'double');
% 写入数据
ncwrite(anomaly_file, 'lon', lon);
ncwrite(anomaly_file, 'lat', lat_selected);
ncwrite(anomaly_file, 'precipitation_anomaly', anomaly_data);
ncwrite(anomaly_file, 'time', time_values);
% 全局属性
ncwriteatt(anomaly_file, '/', 'title', 'GPM Daily Precipitation Anomaly (30S-30N)');
ncwriteatt(anomaly_file, '/', 'source', 'GPM IMERG Half-Hourly Data');
ncwriteatt(anomaly_file, '/', 'date_created', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
ncwriteatt(anomaly_file, '/', 'latitude_range', '30S to 30N');
ncwriteatt(anomaly_file, '/', 'time_coverage_start', '20220101T00:00:00Z');
ncwriteatt(anomaly_file, '/', 'time_coverage_end', '20231231T23:59:59Z');
ncwriteatt(anomaly_file, '/', 'units', 'mm');
ncwriteatt(anomaly_file, '/', 'long_name', 'Daily precipitation anomaly');
ncwriteatt(anomaly_file, '/', 'method', '15-year mean removed + FFT filtering (first 3 harmonics)');

fprintf('异常值文件保存完成: %\n', anomaly_file);
fprintf('所有处理完成！纬度范围: 30°S ~ 30°N\n');
clear normalized_precip original_daily_precipitation subset_normalized_precip fit_climatology;
