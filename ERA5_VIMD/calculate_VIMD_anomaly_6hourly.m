clear; clc;

%% 参数设置
input_path = 'E:\Results_of_Freddy\VIMD_200901_202312_every_6hours';
output_path = 'E:\Results_of_Freddy\VIMD_anomaly_6hourly';

% 创建输出目录
if ~exist(output_path, 'dir')
    mkdir(output_path);
end

%% 步骤1: 读取所有文件，计算15年平均值和标准化VIMD
fprintf('步骤1: 计算15年平均值和标准化VIMD\n');

% 生成所有月份的文件名
years = 2009:2023;
months = 1:12;
file_list = {};
file_dates = [];

for y = years
    for m = months
        if y == 2023 && m > 12
            continue; % 2023年只有12个月
        end
        filename = sprintf('%04d%02d_VIMD.nc', y, m);
        filepath = fullfile(input_path, filename);
        
        if exist(filepath, 'file')
            file_list{end+1} = filename;
            file_dates = [file_dates; datetime(y, m, 1)];
        else
            fprintf('警告: 文件不存在: %s\n', filepath);
        end
    end
end

% 按日期排序
[file_dates, sort_idx] = sort(file_dates);
file_list = file_list(sort_idx);
n_files = length(file_list);
fprintf('找到 %d 个文件\n', n_files);

% 读取第一个文件获取维度信息
first_file = fullfile(input_path, file_list{1});
lon = ncread(first_file, 'longitude');  % 720x1
lat = ncread(first_file, 'latitude');   % 81x1

nLon = length(lon);  % 720
nLat = length(lat);  % 81

% 初始化累加变量
total_vimd = zeros(nLon, nLat, 'double');
valid_count = zeros(nLon, nLat, 'double');

% 存储所有时间步的时间戳
all_times = [];

% 步骤1a: 计算15年平均
fprintf('计算15年平均...\n');
for f = 1:n_files
    filename = fullfile(input_path, file_list{f});
    
    % 读取VIMD数据
    vimd = ncread(filename, 'vimd');  % 720x81x124
    time_data = ncread(filename, 'valid_time');  % 124x1
    
    % 扩展时间数组
    all_times = [all_times; time_data];
    
    % 计算该月的平均值（沿时间维）
    month_mean = mean(vimd, 3, 'omitnan');
    
    % 累加
    total_vimd = total_vimd + month_mean;
    valid_count = valid_count + 1;
    
    if mod(f, 12) == 0
        fprintf('  已处理 %d/%d 年...\n', f/12, length(years));
    end
end

% 计算15年月平均
vimd_15years_mean = total_vimd ./ valid_count;

% 步骤1b: 标准化VIMD并存储
fprintf('计算标准化VIMD...\n');
% 预分配标准化数据数组
n_timesteps_total = length(all_times);
vimd_normalized_all = zeros(nLon, nLat, n_timesteps_total, 'single');

current_idx = 1;
for f = 1:n_files
    filename = fullfile(input_path, file_list{f});
    
    % 读取VIMD数据
    vimd = ncread(filename, 'vimd');  % 720x81x124
    n_timesteps = size(vimd, 3);
    
    % 计算标准化值
    for t = 1:n_timesteps
        vimd_normalized_all(:, :, current_idx) = ...
            single(vimd(:, :, t) - vimd_15years_mean);
        current_idx = current_idx + 1;
    end
    
    if mod(f, 12) == 0
        fprintf('  已标准化 %d/%d 年...\n', f/12, length(years));
    end
end

fprintf('步骤1完成: 15年平均和标准化计算完成\n');

%% 步骤2: 计算气候态（按年积日，每天4个时次）
fprintf('步骤2: 计算气候态...\n');

% 将时间转换为日期时间
base_date = datetime(1970, 1, 1);
all_datetimes = base_date + seconds(all_times);

% 创建DOY（年积日）索引，1-365，每天4个时次（00, 06, 12, 18）
% 忽略闰年的2月29日
doy_hour_index = zeros(length(all_datetimes), 1);

% 预定义每月的累积天数（非闰年）
cum_days = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];

% 计算每个时间步的DOY和小时索引
for i = 1:length(all_datetimes)
    dt = all_datetimes(i);
    year_val = year(dt);
    month_val = month(dt);
    day_val = day(dt);
    hour_val = hour(dt);
    
    % 检查是否是闰年的2月29日
    is_leap_year = (mod(year_val, 4) == 0 && mod(year_val, 100) ~= 0) || (mod(year_val, 400) == 0);
    is_feb29 = (month_val == 2 && day_val == 29);
    
    if is_leap_year && is_feb29
        doy_hour_index(i) = -1;  % 标记为跳过
        continue;
    end
    
    % 计算DOY（1-365）
    doy = cum_days(month_val) + day_val;
    
    % 计算小时索引（1-4）
    hour_idx = floor(hour_val / 6) + 1;
    
    % 组合DOY和小时索引（1-1460）
    doy_hour_index(i) = (doy - 1) * 4 + hour_idx;
end

% 初始化气候态数组
climatology = zeros(nLon, nLat, 365*4, 'single');  % 720x81x1460
climatology_count = zeros(nLon, nLat, 365*4, 'single');

% 累加数据到气候态
fprintf('累加数据到气候态...\n');
for i = 1:length(all_datetimes)
    doy_hour = doy_hour_index(i);
    
    if doy_hour > 0  % 跳过-1（闰年2月29日）
        vimd_norm = vimd_normalized_all(:, :, i);
        
        % 使用矩阵运算累加
        climatology(:, :, doy_hour) = climatology(:, :, doy_hour) + vimd_norm;
        climatology_count(:, :, doy_hour) = climatology_count(:, :, doy_hour) + 1;
    end
    
    if mod(i, 10000) == 0
        fprintf('  已处理 %d/%d 个时间步...\n', i, length(all_datetimes));
    end
end

% 计算平均值
valid_mask = climatology_count > 0;
climatology(valid_mask) = climatology(valid_mask) ./ climatology_count(valid_mask);
climatology(~valid_mask) = NaN;

fprintf('气候态计算完成，维度: %dx%dx%d\n', size(climatology, 1), size(climatology, 2), size(climatology, 3));

%% 步骤3: 傅里叶滤波（保留前三阶谐波）
fprintf('步骤3: 傅里叶滤波...\n');

[nLon, nLat, nClimTimesteps] = size(climatology);  % 720, 81, 1460
fit_climatology = zeros(size(climatology), 'single');

% 对每个格点进行傅里叶滤波
for i = 1:nLon
    for j = 1:nLat
        time_series = squeeze(climatology(i, j, :));
        
        if any(isnan(time_series))
            % 如果有NaN，使用插值
            nan_idx = isnan(time_series);
            if all(nan_idx)
                % 如果全部是NaN，保持NaN
                fit_climatology(i, j, :) = time_series;
                continue;
            end
            
            % 线性插值
            x = 1:length(time_series);
            time_series(nan_idx) = interp1(x(~nan_idx), time_series(~nan_idx), x(nan_idx), 'linear', 'extrap');
        end
        
        % 傅里叶变换
        fft_series = fft(time_series);
        n = length(fft_series);
        
        % 保留直流分量和前3阶谐波（共7个系数）
        % 注意：MATLAB的FFT是对称的，需要保留前4个和后3个系数
        fft_filtered = zeros(size(fft_series));
        fft_filtered(1:4) = fft_series(1:4);  % 直流+前三阶
        fft_filtered(end-2:end) = fft_series(end-2:end);  % 对称部分
        
        % 逆傅里叶变换
        fit_series = real(ifft(fft_filtered));
        fit_climatology(i, j, :) = fit_series;
    end
    
    if mod(i, 100) == 0
        fprintf('  已处理 %d/%d 个经度...\n', i, nLon);
    end
end

fprintf('傅里叶滤波完成\n');

%% 步骤4: 计算2022-2023年的异常值并保存
fprintf('步骤4: 计算2022-2023年的异常值...\n');

% 提取2022-2023年的数据
target_start = datetime(2022, 1, 1);
target_end = datetime(2023, 12, 31, 23, 59, 59);

% 找到目标时间段的数据索引
target_mask = (all_datetimes >= target_start) & (all_datetimes <= target_end);
target_indices = find(target_mask);

% 创建输出数组
n_target_timesteps = length(target_indices);
vimd_anomaly = zeros(nLon, nLat, n_target_timesteps, 'single');
output_times = all_times(target_indices);
output_datetimes = all_datetimes(target_indices);

fprintf('处理 %d 个时间步 (2022-01-01 到 2023-12-31)\n', n_target_timesteps);

% 计算异常值
for i = 1:length(target_indices)
    idx = target_indices(i);
    dt = all_datetimes(idx);
    
    % 计算DOY和小时索引
    year_val = year(dt);
    month_val = month(dt);
    day_val = day(dt);
    hour_val = hour(dt);
    
    % 计算DOY
    if (mod(year_val, 4) == 0 && mod(year_val, 100) ~= 0) || (mod(year_val, 400) == 0)
        % 闰年
        if month_val > 2
            doy = cum_days(month_val) + day_val - 1;
        else
            doy = cum_days(month_val) + day_val;
        end
    else
        % 非闰年
        doy = cum_days(month_val) + day_val;
    end
    
    % 计算小时索引
    hour_idx = floor(hour_val / 6) + 1;
    
    % 计算气候态索引
    clim_idx = (doy - 1) * 4 + hour_idx;
    
    % 计算异常值
    vimd_norm = vimd_normalized_all(:, :, idx);
    clim_value = fit_climatology(:, :, clim_idx);
    vimd_anomaly(:, :, i) = vimd_norm - clim_value;
    
    if mod(i, 1000) == 0
        fprintf('  已处理 %d/%d 个时间步...\n', i, n_target_timesteps);
    end
end

%% 步骤5: 保存为NetCDF文件
fprintf('步骤5: 保存为NetCDF文件...\n');

output_file = fullfile(output_path, 'VIMD_anomaly_6hourly_20220101_20231231.nc');

% 删除已存在的文件
if exist(output_file, 'file')
    delete(output_file);
end

% 创建维度
nccreate(output_file, 'longitude', 'Dimensions', {'longitude', nLon}, 'Datatype', 'double');
nccreate(output_file, 'latitude', 'Dimensions', {'latitude', nLat}, 'Datatype', 'double');
nccreate(output_file, 'time', 'Dimensions', {'time', n_target_timesteps}, 'Datatype', 'double');

% 创建变量
nccreate(output_file, 'vimd_anomaly', ...
    'Dimensions', {'longitude', nLon, 'latitude', nLat, 'time', n_target_timesteps}, ...
    'Datatype', 'single', ...
    'FillValue', single(NaN));

% 写入数据
ncwrite(output_file, 'longitude', lon);
ncwrite(output_file, 'latitude', lat);
ncwrite(output_file, 'time', output_times);
ncwrite(output_file, 'vimd_anomaly', vimd_anomaly);

% 添加属性
ncwriteatt(output_file, 'longitude', 'units', 'degrees_east');
ncwriteatt(output_file, 'longitude', 'standard_name', 'longitude');
ncwriteatt(output_file, 'longitude', 'long_name', 'longitude');

ncwriteatt(output_file, 'latitude', 'units', 'degrees_north');
ncwriteatt(output_file, 'latitude', 'standard_name', 'latitude');
ncwriteatt(output_file, 'latitude', 'long_name', 'latitude');

ncwriteatt(output_file, 'time', 'units', 'seconds since 1970-01-01');
ncwriteatt(output_file, 'time', 'standard_name', 'time');
ncwriteatt(output_file, 'time', 'long_name', 'time');
ncwriteatt(output_file, 'time', 'calendar', 'proleptic_gregorian');

ncwriteatt(output_file, 'vimd_anomaly', 'units', 'kg m^-2 s^-1');
ncwriteatt(output_file, 'vimd_anomaly', 'standard_name', 'vertical_integral_of_moisture_divergence_anomaly');
ncwriteatt(output_file, 'vimd_anomaly', 'long_name', 'Vertically Integrated Moisture Divergence Anomaly');
ncwriteatt(output_file, 'vimd_anomaly', 'description', 'VIMD anomaly calculated by removing 15-year mean and FFT-filtered climatology (first 3 harmonics)');

% 全局属性
ncwriteatt(output_file, '/', 'title', 'Vertically Integrated Moisture Divergence (VIMD) Anomaly');
ncwriteatt(output_file, '/', 'source', 'Calculated from ERA5 u, v, q data');
ncwriteatt(output_file, '/', 'history', sprintf('Created: %s', datestr(now, 'dd-mmm-yyyy HH:MM:SS')));
ncwriteatt(output_file, '/', 'Conventions', 'CF-1.7');
ncwriteatt(output_file, '/', 'base_period', '2009-01-01 to 2023-12-31');
ncwriteatt(output_file, '/', 'target_period', '2022-01-01 to 2023-12-31');
ncwriteatt(output_file, '/', 'temporal_resolution', '6-hourly');
ncwriteatt(output_file, '/', 'spatial_resolution', '0.5x0.5 degree');
ncwriteatt(output_file, '/', 'latitude_range', '10N to 30S');
ncwriteatt(output_file, '/', 'longitude_range', '0 to 360');
ncwriteatt(output_file, '/', 'method', '15-year mean removed + FFT filtering (first 3 harmonics)');
ncwriteatt(output_file, '/', 'author', 'For research on Tropical Cyclone Freddy (2023)');

fprintf('处理完成！\n');
fprintf('输出文件: %s\n', output_file);
fprintf('文件大小: %.2f GB\n', getfield(dir(output_file), 'bytes') / 1e9);

%% 清理内存
clear vimd_normalized_all climatology fit_climatology;
fprintf('所有处理完成！\n');