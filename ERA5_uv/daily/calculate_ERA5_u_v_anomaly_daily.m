clear; clc;

%% 设置路径和文件
input_path = 'E:\Results_of_Freddy_ChenYong_version2\u_v_daily';
input_file = 'u_v_daily_20090101_20231231.nc';
output_file = 'u_v_anomaly_daily_20220101_20231231.nc';
output_path = input_path;

fprintf('开始处理ERA5风场数据...\n');

%% 步骤1: 一次性处理文件读取、15年平均值和标准化风场计算
fprintf('步骤1: 一次性处理文件读取、15年平均值和标准化风场计算 (30°N~30°S)...\n');

% 读取纬度、经度和时间信息
lat = ncread(fullfile(input_path, input_file), 'latitude');
lon = ncread(fullfile(input_path, input_file), 'longitude');
time = ncread(fullfile(input_path, input_file), 'time');

% 维度信息
nLat = length(lat);    % 121个纬度点 (30°N ~ 30°S)
nLon = length(lon);    % 720个经度点 (0° ~ 359.5°)
nTime = length(time);  % 5478个时间点 (2009-01-01 ~ 2023-12-31)

fprintf('数据维度: 经度=%d, 纬度=%d, 时间=%d\n', nLon, nLat, nTime);
fprintf('纬度范围: %.1f°N ~ %.1f°S\n', lat(1), lat(end));
fprintf('经度范围: %.1f°E ~ %.1f°E\n', lon(1), lon(end));

% 读取u和v数据
fprintf('正在读取u分量数据...\n');
u_daily_mean = ncread(fullfile(input_path, input_file), 'u_daily_mean'); % 720x121x5478

fprintf('正在读取v分量数据...\n');
v_daily_mean = ncread(fullfile(input_path, input_file), 'v_daily_mean'); % 720x121x5478

% 检查是否有NaN值并转换为0用于计算平均值
u_for_sum = u_daily_mean;
v_for_sum = v_daily_mean;

% 处理NaN值 - 修复索引语法问题
u_nan_mask = isnan(u_daily_mean);
v_nan_mask = isnan(v_daily_mean);

% 使用标准MATLAB语法替换NaN值
u_for_sum(isnan(u_for_sum)) = 0;
v_for_sum(isnan(v_for_sum)) = 0;

% 计算有效值计数 - 修复：使用sum函数的正确语法
u_valid_count = sum(~isnan(u_daily_mean), 3);
v_valid_count = sum(~isnan(v_daily_mean), 3);

% 计算15年平均值
fprintf('计算u分量15年平均值...\n');
% 使用安全的除法，避免除以0
u_mean = zeros(nLon, nLat, 'single');
for i = 1:nLon
    for j = 1:nLat
        if u_valid_count(i, j) > 0
            u_mean(i, j) = sum(u_for_sum(i, j, :)) / u_valid_count(i, j);
        else
            u_mean(i, j) = NaN;
        end
    end
    if mod(i, 100) == 0
        fprintf('  已处理 %d/%d 经度...\n', i, nLon);
    end
end

fprintf('计算v分量15年平均值...\n');
v_mean = zeros(nLon, nLat, 'single');
for i = 1:nLon
    for j = 1:nLat
        if v_valid_count(i, j) > 0
            v_mean(i, j) = sum(v_for_sum(i, j, :)) / v_valid_count(i, j);
        else
            v_mean(i, j) = NaN;
        end
    end
    if mod(i, 100) == 0
        fprintf('  已处理 %d/%d 经度...\n', i, nLon);
    end
end

% 计算标准化风场（原始值减去平均值）
fprintf('计算标准化风场...\n');
u_normalized = zeros(size(u_daily_mean), 'single');
v_normalized = zeros(size(v_daily_mean), 'single');

for t = 1:nTime
    % 获取当前时间步的数据
    u_current = u_daily_mean(:, :, t);
    v_current = v_daily_mean(:, :, t);
    
    % 计算标准化值
    u_norm = u_current - u_mean;
    v_norm = v_current - v_mean;
    
    % 恢复NaN值
    u_norm(isnan(u_current)) = NaN;
    v_norm(isnan(v_current)) = NaN;
    
    % 存储结果
    u_normalized(:, :, t) = u_norm;
    v_normalized(:, :, t) = v_norm;
    
    if mod(t, 500) == 0
        fprintf('  已处理 %d/%d 个时间步...\n', t, nTime);
    end
end

% 一次性保存所有相关数据
save(fullfile(output_path, 'u_v_mean_30N_30S.mat'), 'u_mean', 'v_mean', 'lon', 'lat', '-v7.3');
save(fullfile(output_path, 'original_u_v_daily_30N_30S.mat'), 'u_daily_mean', 'v_daily_mean', 'lon', 'lat', 'time', '-v7.3');
save(fullfile(output_path, 'normalized_u_v_30N_30S.mat'), 'u_normalized', 'v_normalized', 'lon', 'lat', 'time', '-v7.3');

fprintf('步骤1完成: 15年平均、原始日风场和标准化风场计算并保存\n');

% 清理不再需要的大变量
clear u_for_sum v_for_sum u_current v_current u_norm v_norm;

%% 步骤2: 计算气候态并进行傅里叶滤波
fprintf('步骤2: 计算气候态并进行傅里叶滤波 (30°N~30°S)...\n');

% 生成日期序列 (2009年1月1日到2023年12月31日)
start_date = datetime(2009, 1, 1);
end_date = datetime(2023, 12, 31);
date_sequence = start_date:end_date;

% 确保日期序列长度与数据一致
if length(date_sequence) ~= nTime
    error('日期序列长度与数据时间数量不匹配!');
end

% 初始化气候态数组 - 使用365天
fprintf('初始化气候态数组...\n');
u_climatology = zeros(nLon, nLat, 365, 'single'); % 720x121x365
v_climatology = zeros(nLon, nLat, 365, 'single'); % 720x121x365
u_count = zeros(nLon, nLat, 365, 'single'); % 720x121x365
v_count = zeros(nLon, nLat, 365, 'single'); % 720x121x365

% 处理每一天的数据计算气候态
fprintf('计算气候态...\n');
for i = 1:length(date_sequence)
    current_date = date_sequence(i);
    
    % 提取日期信息
    year_val = year(current_date);
    month_val = month(current_date);
    day_val = day(current_date);
    
    % 计算年积日 - 使用预定义的累积天数数组
    cum_days = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    % 如果是闰年的2月29日，跳过处理
    is_leap_year = (mod(year_val, 4) == 0 && mod(year_val, 100) ~= 0) || (mod(year_val, 400) == 0);
    is_feb_29 = (month_val == 2 && day_val == 29);
    if is_leap_year && is_feb_29
        continue;
    end
    doy = cum_days(month_val) + day_val;
    
    % 从normalized_u_v中获取当前日期的数据
    u_data = u_normalized(:, :, i);
    v_data = v_normalized(:, :, i);
    
    % 累加到对应年积日
    for lon_idx = 1:nLon
        for lat_idx = 1:nLat
            % 检查u数据是否为有效值
            if ~isnan(u_data(lon_idx, lat_idx))
                u_climatology(lon_idx, lat_idx, doy) = u_climatology(lon_idx, lat_idx, doy) + u_data(lon_idx, lat_idx);
                u_count(lon_idx, lat_idx, doy) = u_count(lon_idx, lat_idx, doy) + 1;
            end
            
            % 检查v数据是否为有效值
            if ~isnan(v_data(lon_idx, lat_idx))
                v_climatology(lon_idx, lat_idx, doy) = v_climatology(lon_idx, lat_idx, doy) + v_data(lon_idx, lat_idx);
                v_count(lon_idx, lat_idx, doy) = v_count(lon_idx, lat_idx, doy) + 1;
            end
        end
    end
    
    if mod(i, 500) == 0
        fprintf('  已处理 %d/%d 天数据计算气候态...\n', i, length(date_sequence));
    end
end

% 计算气候态平均值
fprintf('计算气候态平均值...\n');
for lon_idx = 1:nLon
    for lat_idx = 1:nLat
        for doy = 1:365
            % 处理u分量
            if u_count(lon_idx, lat_idx, doy) > 0
                u_climatology(lon_idx, lat_idx, doy) = u_climatology(lon_idx, lat_idx, doy) / u_count(lon_idx, lat_idx, doy);
            else
                u_climatology(lon_idx, lat_idx, doy) = NaN;
            end
            
            % 处理v分量
            if v_count(lon_idx, lat_idx, doy) > 0
                v_climatology(lon_idx, lat_idx, doy) = v_climatology(lon_idx, lat_idx, doy) / v_count(lon_idx, lat_idx, doy);
            else
                v_climatology(lon_idx, lat_idx, doy) = NaN;
            end
        end
    end
    
    if mod(lon_idx, 100) == 0
        fprintf('  已完成 %d/%d 经度的平均计算...\n', lon_idx, nLon);
    end
end

% 保存气候态数据
save(fullfile(output_path, 'u_v_climatology_30N_30S.mat'), 'u_climatology', 'v_climatology', 'lon', 'lat', '-v7.3');

fprintf('气候态计算完成，维度: u=%dx%dx%d, v=%dx%dx%d\n', ...
    size(u_climatology, 1), size(u_climatology, 2), size(u_climatology, 3), ...
    size(v_climatology, 1), size(v_climatology, 2), size(v_climatology, 3));

%% 步骤3: 傅里叶滤波
fprintf('步骤3: 傅里叶滤波 (30°N~30°S)...\n');

[nLon_sel, nLat_sel, nDays] = size(u_climatology);
u_fit_climatology = zeros(size(u_climatology), 'single');
v_fit_climatology = zeros(size(v_climatology), 'single');

fprintf('开始傅里叶滤波，格点总数: %d x %d\n', nLon_sel, nLat_sel);

% 对每个格点进行傅里叶滤波
for i = 1:nLon_sel
    for j = 1:nLat_sel
        % 提取该格点的u分量年循环序列
        u_time_series = squeeze(u_climatology(i, j, :));
        v_time_series = squeeze(v_climatology(i, j, :));
        
        % 检查是否为全NaN
        if all(isnan(u_time_series)) || all(isnan(v_time_series))
            continue;
        end
        
        % 处理u分量
        if ~all(isnan(u_time_series))
            % 用0填充NaN值用于傅里叶变换
            u_series_filled = u_time_series;
            u_nan_idx = isnan(u_time_series);
            u_series_filled(u_nan_idx) = 0;
            
            % 傅里叶变换
            u_fft_series = fft(u_series_filled);
            
            % 保留前3个和后3个系数（对应前三阶谐波）
            harmonics_to_keep = 3;
            u_filtered_fft = zeros(size(u_fft_series), 'single');
            
            % 保留直流分量和前3阶谐波
            u_filtered_fft(1:harmonics_to_keep+1) = u_fft_series(1:harmonics_to_keep+1);
            % 保留对应的负频率分量
            if harmonics_to_keep > 0
                u_filtered_fft(end-harmonics_to_keep+1:end) = u_fft_series(end-harmonics_to_keep+1:end);
            end
            
            % 逆傅里叶变换
            u_fit_series = real(ifft(u_filtered_fft));
            % 将NaN位置恢复为NaN
            u_fit_series(u_nan_idx) = NaN;
            u_fit_climatology(i, j, :) = u_fit_series;
        end
        
        % 处理v分量
        if ~all(isnan(v_time_series))
            % 用0填充NaN值用于傅里叶变换
            v_series_filled = v_time_series;
            v_nan_idx = isnan(v_time_series);
            v_series_filled(v_nan_idx) = 0;
            
            % 傅里叶变换
            v_fft_series = fft(v_series_filled);
            
            % 保留前3个和后3个系数（对应前三阶谐波）
            harmonics_to_keep = 3;
            v_filtered_fft = zeros(size(v_fft_series), 'single');
            
            % 保留直流分量和前3阶谐波
            v_filtered_fft(1:harmonics_to_keep+1) = v_fft_series(1:harmonics_to_keep+1);
            % 保留对应的负频率分量
            if harmonics_to_keep > 0
                v_filtered_fft(end-harmonics_to_keep+1:end) = v_fft_series(end-harmonics_to_keep+1:end);
            end
            
            % 逆傅里叶变换
            v_fit_series = real(ifft(v_filtered_fft));
            % 将NaN位置恢复为NaN
            v_fit_series(v_nan_idx) = NaN;
            v_fit_climatology(i, j, :) = v_fit_series;
        end
    end
    
    if mod(i, 100) == 0
        fprintf('  已完成 %d/%d 经度...\n', i, nLon_sel);
    end
end

save(fullfile(output_path, 'u_v_fit_climatology_30N_30S.mat'), 'u_fit_climatology', 'v_fit_climatology', 'lon', 'lat', '-v7.3');
fprintf('傅里叶滤波完成\n');

%% 步骤4: 计算最终异常值并保存
fprintf('步骤4: 计算最终异常值 (30°N~30°S)...\n');

% 确定2022-2023年在整个数据序列中的位置
target_start_date = datetime(2022, 1, 1);
target_end_date = datetime(2023, 12, 31);

% 计算索引位置
start_idx = days(target_start_date - start_date) + 1;
end_idx = days(target_end_date - start_date) + 1;

% 提取2022-2023年的标准化风场数据
fprintf('提取2022-2023年数据...\n');
u_subset_normalized = u_normalized(:, :, start_idx:end_idx); % 720x121x730
v_subset_normalized = v_normalized(:, :, start_idx:end_idx); % 720x121x730
nTime_target = size(u_subset_normalized, 3); % 730

fprintf('开始处理 %d 天的异常值计算 (30°N~30°S)...\n', nTime_target);
fprintf('数据时间范围: %s 到 %s\n', datestr(target_start_date), datestr(target_end_date));

% 生成2022-2023年日期序列
target_dates = target_start_date:target_end_date;

% 预分配异常值数据数组
u_anomaly = zeros(nLon, nLat, nTime_target, 'single'); % 720x121x730
v_anomaly = zeros(nLon, nLat, nTime_target, 'single'); % 720x121x730
time_values = zeros(nTime_target, 1); % 730x1

% 处理每一天的数据计算异常值
fprintf('计算异常值...\n');
for i = 1:nTime_target
    current_date = target_dates(i);
    
    % 从日期序列获取日期信息
    date_num = datenum(current_date);
    time_values(i) = date_num;
    
    % 解析日期
    year_val = year(current_date);
    month_val = month(current_date);
    day_val = day(current_date);
    
    % 计算年积日
    cum_days = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    doy = cum_days(month_val) + day_val;
    
    % 获取当前日期的标准化风场数据和对应日期的滤波气候态
    u_normalized_current = u_subset_normalized(:, :, i);
    v_normalized_current = v_subset_normalized(:, :, i);
    u_climate_value = u_fit_climatology(:, :, doy);
    v_climate_value = v_fit_climatology(:, :, doy);
    
    % 计算异常值
    u_anom = u_normalized_current - u_climate_value;
    v_anom = v_normalized_current - v_climate_value;
    
    % 处理缺失值
    u_missing_mask = isnan(u_normalized_current) | isnan(u_climate_value);
    v_missing_mask = isnan(v_normalized_current) | isnan(v_climate_value);
    
    u_anom(u_missing_mask) = NaN;
    v_anom(v_missing_mask) = NaN;
    
    u_anomaly(:, :, i) = u_anom;
    v_anomaly(:, :, i) = v_anom;
    
    if mod(i, 100) == 0
        fprintf('  已计算 %d/%d 天的异常值...\n', i, nTime_target);
    end
end

% 保存异常值数据到mat文件
save(fullfile(output_path, 'u_v_anomaly_30N_30S.mat'), 'u_anomaly', 'v_anomaly', 'lon', 'lat', 'time_values', '-v7.3');
fprintf('异常值数据已保存到 u_v_anomaly_30N_30S.mat\n');

%% 创建并保存NetCDF文件
fprintf('创建NetCDF文件...\n');
output_nc_file = fullfile(output_path, output_file);

% 删除已存在的文件（如果存在）
if exist(output_nc_file, 'file')
    delete(output_nc_file);
end

% 创建NetCDF文件 - 使用正确的FillValue
nccreate(output_nc_file, 'longitude', ...
         'Dimensions', {'longitude', nLon}, ...
         'Datatype', 'single');
nccreate(output_nc_file, 'latitude', ...
         'Dimensions', {'latitude', nLat}, ...
         'Datatype', 'single');
nccreate(output_nc_file, 'time', ...
         'Dimensions', {'time', nTime_target}, ...
         'Datatype', 'double');
% 创建变量时指定FillValue
nccreate(output_nc_file, 'u_anomaly', ...
         'Dimensions', {'longitude', nLon, 'latitude', nLat, 'time', nTime_target}, ...
         'Datatype', 'single', ...
         'FillValue', single(NaN)); % 指定单精度NaN作为FillValue
nccreate(output_nc_file, 'v_anomaly', ...
         'Dimensions', {'longitude', nLon, 'latitude', nLat, 'time', nTime_target}, ...
         'Datatype', 'single', ...
         'FillValue', single(NaN)); % 指定单精度NaN作为FillValue

% 写入数据
ncwrite(output_nc_file, 'longitude', lon);
ncwrite(output_nc_file, 'latitude', lat);
ncwrite(output_nc_file, 'time', time_values);
ncwrite(output_nc_file, 'u_anomaly', u_anomaly);
ncwrite(output_nc_file, 'v_anomaly', v_anomaly);

% 添加变量属性 - 注意：FillValue已经在nccreate中设置，这里不需要再设置
ncwriteatt(output_nc_file, 'longitude', 'units', 'degrees_east');
ncwriteatt(output_nc_file, 'longitude', 'long_name', 'longitude');
ncwriteatt(output_nc_file, 'longitude', 'standard_name', 'longitude');

ncwriteatt(output_nc_file, 'latitude', 'units', 'degrees_north');
ncwriteatt(output_nc_file, 'latitude', 'long_name', 'latitude');
ncwriteatt(output_nc_file, 'latitude', 'standard_name', 'latitude');

% 使用正确的time单位（参考原始文件）
ncwriteatt(output_nc_file, 'time', 'units', 'days since 2009-01-01 00:00:00');
ncwriteatt(output_nc_file, 'time', 'long_name', 'time');
ncwriteatt(output_nc_file, 'time', 'calendar', 'gregorian');

ncwriteatt(output_nc_file, 'u_anomaly', 'units', 'm s^-1');
ncwriteatt(output_nc_file, 'u_anomaly', 'long_name', 'Daily eastward wind anomaly at 850 hPa');
ncwriteatt(output_nc_file, 'u_anomaly', 'standard_name', 'eastward_wind');
ncwriteatt(output_nc_file, 'u_anomaly', 'pressure_level', 850);
ncwriteatt(output_nc_file, 'u_anomaly', 'coordinates', 'longitude latitude time');
% 注意：这里不再需要设置missing_value属性，因为已经通过FillValue设置了

ncwriteatt(output_nc_file, 'v_anomaly', 'units', 'm s^-1');
ncwriteatt(output_nc_file, 'v_anomaly', 'long_name', 'Daily northward wind anomaly at 850 hPa');
ncwriteatt(output_nc_file, 'v_anomaly', 'standard_name', 'northward_wind');
ncwriteatt(output_nc_file, 'v_anomaly', 'pressure_level', 850);
ncwriteatt(output_nc_file, 'v_anomaly', 'coordinates', 'longitude latitude time');
% 注意：这里不再需要设置missing_value属性，因为已经通过FillValue设置了

% 添加全局属性
ncwriteatt(output_nc_file, '/', 'title', 'Daily mean wind anomaly at 850 hPa from ERA5');
ncwriteatt(output_nc_file, '/', 'source', 'ERA5 reanalysis');
ncwriteatt(output_nc_file, '/', 'institution', 'European Centre for Medium-Range Weather Forecasts');
ncwriteatt(output_nc_file, '/', 'history', sprintf('Created by MATLAB on %s', datestr(now, 'dd-mmm-yyyy HH:MM:SS')));
ncwriteatt(output_nc_file, '/', 'Conventions', 'CF-1.7');
ncwriteatt(output_nc_file, '/', 'creation_date', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
ncwriteatt(output_nc_file, '/', 'time_coverage_start', '2022-01-01');
ncwriteatt(output_nc_file, '/', 'time_coverage_end', '2023-12-31');
ncwriteatt(output_nc_file, '/', 'latitude_range', '30.0 to -30.0 degrees_north');
ncwriteatt(output_nc_file, '/', 'longitude_range', '0.0 to 359.5 degrees_east');
ncwriteatt(output_nc_file, '/', 'pressure_level', '850 hPa');
ncwriteatt(output_nc_file, '/', 'spatial_resolution', '0.5 x 0.5 degrees');
ncwriteatt(output_nc_file, '/', 'temporal_resolution', 'daily mean');
ncwriteatt(output_nc_file, '/', 'processing_method', '15-year mean removed + FFT filtering (first 3 harmonics)');
ncwriteatt(output_nc_file, '/', 'reference_period', '2009-01-01 to 2023-12-31');

fprintf('NetCDF文件保存完成: %s\n', output_nc_file);
fprintf('所有处理完成！纬度范围: 30°N ~ 30°S，经度范围: 0° ~ 359.5°\n');
fprintf('输出文件: %s\n', output_nc_file);

%% 显示最终文件信息
fprintf('\n最终文件信息:\n');
ncdisp(output_nc_file);