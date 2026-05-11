%% 设置路径和参数
clear; clc; close all;

% 输入数据路径
input_path = 'E:\Original_Data_of_Freddy\ERA5_dv_q_uv_200901_202312_every_6hours';
% 输出数据路径
output_path = 'E:\Results_of_Freddy\VIMD_200901_202312_every_6hours';

% 创建输出目录
if ~exist(output_path, 'dir')
    mkdir(output_path);
end

% 检查目录权限
[status, msg] = fileattrib(output_path);
if ~status
    error('无法访问输出目录: %s\n错误信息: %s', output_path, msg);
end

% 常数
g = 9.8;  % 重力加速度 (m/s^2)
a = 6371000;  % 地球半径 (m)

% 时间范围
start_year = 2009;
end_year = 2023;

% 获取第一个文件的维度信息（所有文件维度相同）
sample_file = fullfile(input_path, '200901_uv.nc');
lon = ncread(sample_file, 'longitude');
lat = ncread(sample_file, 'latitude');
plev = ncread(sample_file, 'pressure_level');
nlon = length(lon);
nlat = length(lat);
nlev = length(plev);

fprintf('网格信息: 经度=%d, 纬度=%d, 气压层=%d\n', nlon, nlat, nlev);

% 预计算常数和权重
fprintf('预计算常数和权重...\n');

% 将气压从hPa转换为Pa，并计算垂直权重
p_Pa = plev * 100;  % 转换为Pa

% 计算垂直权重 (采用梯形积分法)
w = zeros(nlev, 1);  % 权重，单位：Pa
w(1) = (p_Pa(1) - p_Pa(2)) / 2;  % 第一层
for k = 2:nlev-1
    w(k) = (p_Pa(k-1) - p_Pa(k+1)) / 2;  % 中间层
end
w(nlev) = (p_Pa(nlev-1) - p_Pa(nlev)) / 2;  % 最后一层

% 计算纬度的余弦值（用于散度计算）
lat_rad = deg2rad(lat);  % 纬度转换为弧度
cos_lat = cos(lat_rad);  % cos(φ) - [nlat, 1]

% 扩展cos_lat到2D网格，用于快速计算
cos_lat_2d = repmat(cos_lat', nlon, 1);  % [nlon, nlat]

% 经度分辨率（转换为弧度）
dlambda = deg2rad(lon(2) - lon(1));  % 经度间隔（弧度）

% 纬度分辨率（转换为弧度）
dphi = deg2rad(lat(2) - lat(1));  % 纬度间隔（弧度）

% 预计算分母项 1/(a * cosφ)
inv_a_coslat = 1 ./ (a * cos_lat_2d);  % [nlon, nlat]

% 预计算用于差分的索引矩阵
fprintf('预计算差分索引...\n');
% 经度方向差分索引
i_west = [nlon, 1:nlon-1];      % 西边索引（循环边界）
i_east = [2:nlon, 1];           % 东边索引（循环边界）

% 纬度方向差分索引（边界处理）
j_north = [1, 1:nlat-1];        % 北边索引（边界复制）
j_south = [2:nlat, nlat];       % 南边索引（边界复制）

%% 处理每个月的数据
for year = start_year:end_year
    for month = 1:12
        % 构建文件名
        year_str = num2str(year);
        month_str = sprintf('%02d', month);
        file_prefix = [year_str, month_str];
        
        % UV文件名
        uv_file = fullfile(input_path, [file_prefix, '_uv.nc']);
        % Q文件名
        q_file = fullfile(input_path, [file_prefix, '_q.nc']);
        % 输出文件名
        output_file = fullfile(output_path, [file_prefix, '_VIMD.nc']);
        
        fprintf('\n正在处理: %s年%s月\n', year_str, month_str);
        
        % 检查文件是否存在
        if ~exist(uv_file, 'file') || ~exist(q_file, 'file')
            warning('文件不存在: %s 或 %s，跳过', uv_file, q_file);
            continue;
        end
        
        % 检查输出文件是否已存在
        if exist(output_file, 'file')
            fprintf('  删除已存在的输出文件...\n');
            try
                delete(output_file);
                % 等待文件系统更新
                pause(0.1);
            catch ME
                warning('无法删除已存在的文件: %s\n错误: %s', output_file, ME.message);
                continue;
            end
        end
        
        % 获取时间信息
        time_info = ncinfo(uv_file, 'valid_time');
        ntime = time_info.Size(1);
        fprintf('  时间步数: %d\n', ntime);
        
        % 预分配输出数组
        vimd = zeros(nlon, nlat, ntime, 'single');  % 使用单精度节省内存
        
        % 逐时次处理
        fprintf('  开始处理时次...\n');
        start_time = tic;
        
        % 使用更高效的向量化计算方法
        for t = 1:ntime
            % 每20个时次显示一次进度
            if mod(t, 20) == 0
                fprintf('    处理进度: %d/%d (%.1f%%)\n', t, ntime, 100*t/ntime);
            end
            
            % 读取当前时次的u、v、q数据
            u_t = ncread(uv_file, 'u', [1, 1, 1, t], [nlon, nlat, nlev, 1]);
            v_t = ncread(uv_file, 'v', [1, 1, 1, t], [nlon, nlat, nlev, 1]);
            q_t = ncread(q_file, 'q', [1, 1, 1, t], [nlon, nlat, nlev, 1]);
            
            % 处理可能的NaN值
            u_t(isnan(u_t)) = 0;
            v_t(isnan(v_t)) = 0;
            q_t(isnan(q_t)) = 0;
            
            % 初始化当前时次的VIMD
            vimd_t = zeros(nlon, nlat);
            
            % 逐层计算（使用向量化计算）
            for k = 1:nlev
                % 获取当前层数据
                u_k = squeeze(u_t(:, :, k));  % [nlon, nlat]
                v_k = squeeze(v_t(:, :, k));  % [nlon, nlat]
                q_k = squeeze(q_t(:, :, k));  % [nlon, nlat]
                
                % 计算水汽通量
                qu = q_k .* u_k;  % [nlon, nlat]
                qv = q_k .* v_k;  % [nlon, nlat]
                
                % 计算qv_cos = qv * cosφ
                qv_cos = qv .* cos_lat_2d;  % [nlon, nlat]
                
                % 使用向量化方法计算经度导数 ∂(qu)/∂λ
                qu_west = qu(i_west, :);
                qu_east = qu(i_east, :);
                dqu_dlambda = (qu_east - qu_west) / (2 * dlambda);
                
                % 使用向量化方法计算纬度导数 ∂(qv cosφ)/∂φ
                % 预计算所有边界值
                qv_cos_north_all = qv_cos(:, j_north);
                qv_cos_south_all = qv_cos(:, j_south);
                
                % 初始化纬度导数数组
                dqvcos_dphi = zeros(nlon, nlat);
                
                % 使用向量化方法计算内部点
                if nlat > 2
                    % 内部点：中心差分
                    dqvcos_dphi(:, 2:end-1) = (qv_cos_south_all(:, 2:end-1) - qv_cos_north_all(:, 2:end-1)) / (2 * dphi);
                end
                
                % 边界点：单边差分
                % 北边界
                dqvcos_dphi(:, 1) = (qv_cos_south_all(:, 1) - qv_cos(:, 1)) / dphi;
                
                % 南边界
                dqvcos_dphi(:, end) = (qv_cos(:, end) - qv_cos_north_all(:, end)) / dphi;
                
                % 计算水平散度（向量化）
                div_qV = (dqu_dlambda + dqvcos_dphi) .* inv_a_coslat;
                
                % 将当前层的贡献加到VIMD中
                vimd_t = vimd_t + div_qV * w(k);
            end
            
            % 乘以-1/g得到VIMD
            vimd_t = -1/g * vimd_t;
            
            % 存储结果
            vimd(:, :, t) = vimd_t;
        end
        
        elapsed_time = toc(start_time);
        fprintf('  计算完成，耗时: %.2f 秒 (平均 %.2f 秒/时次)\n', elapsed_time, elapsed_time/ntime);
        
        % 读取时间变量（转换为double类型）
        time = double(ncread(uv_file, 'valid_time'));
        
        % 创建NetCDF文件
        fprintf('  写入NetCDF文件...\n');
       
        % 方法：使用nccreate创建文件结构，然后写入数据
        % 定义文件模式
        nccreate(output_file, 'longitude', 'Dimensions', {'longitude', nlon}, 'Datatype', 'double', 'Format', 'netcdf4');
        nccreate(output_file, 'latitude', 'Dimensions', {'latitude', nlat}, 'Datatype', 'double', 'Format', 'netcdf4');
        nccreate(output_file, 'valid_time', 'Dimensions', {'valid_time', ntime}, 'Datatype', 'double', 'Format', 'netcdf4');
        nccreate(output_file, 'vimd', ...
            'Dimensions', {'longitude', nlon, 'latitude', nlat, 'valid_time', ntime}, ...
            'Datatype', 'single', ...
            'Format', 'netcdf4');
        
        % 写入数据
        ncwrite(output_file, 'longitude', lon);
        ncwrite(output_file, 'latitude', lat);
        ncwrite(output_file, 'valid_time', time);
        ncwrite(output_file, 'vimd', vimd);
        
        % 添加属性
        ncwriteatt(output_file, 'longitude', 'units', 'degrees_east');
        ncwriteatt(output_file, 'longitude', 'standard_name', 'longitude');
        ncwriteatt(output_file, 'longitude', 'long_name', 'longitude');
        
        ncwriteatt(output_file, 'latitude', 'units', 'degrees_north');
        ncwriteatt(output_file, 'latitude', 'standard_name', 'latitude');
        ncwriteatt(output_file, 'latitude', 'long_name', 'latitude');
        
        ncwriteatt(output_file, 'valid_time', 'units', 'seconds since 1970-01-01');
        ncwriteatt(output_file, 'valid_time', 'calendar', 'proleptic_gregorian');
        ncwriteatt(output_file, 'valid_time', 'standard_name', 'time');
        ncwriteatt(output_file, 'valid_time', 'long_name', 'time');
        
        ncwriteatt(output_file, 'vimd', 'units', 'kg m^-2 s^-1');
        ncwriteatt(output_file, 'vimd', 'standard_name', 'vertical_integral_of_moisture_divergence');
        ncwriteatt(output_file, 'vimd', 'long_name', 'Vertically Integrated Moisture Divergence');
        ncwriteatt(output_file, 'vimd', 'description', 'VIMD = -1/g * ∫ ∇·(qV) dp from 1000 hPa to 100 hPa');
        ncwriteatt(output_file, 'vimd', 'g', g);
        ncwriteatt(output_file, 'vimd', 'earth_radius', a);
        
        fprintf('  文件写入完成: %s\n', output_file);
        
        % 验证文件是否成功创建
        if exist(output_file, 'file')
            file_info = dir(output_file);
            fprintf('  文件大小: %.2f MB\n', file_info.bytes / (1024*1024));
        else
            warning('文件未创建: %s', output_file);
        end
        
        % 清理内存
        clear u_t v_t q_t vimd vimd_t time;
    end
end

fprintf('\n所有月份处理完成！\n');

%% 显示统计信息
fprintf('\n===== 处理结果统计 =====\n');

% 检查输出目录中的文件
output_files = dir(fullfile(output_path, '*_VIMD.nc'));
fprintf('生成的文件数量: %d\n', length(output_files));

if ~isempty(output_files)
    % 显示前几个文件的统计信息
    max_files_to_check = min(3, length(output_files));
    for i = 1:max_files_to_check
        file_name = fullfile(output_path, output_files(i).name);
        try
            vimd_sample = ncread(file_name, 'vimd', [1, 1, 1], [10, 10, 1]);
            fprintf('\n文件 %s 的VIMD样本统计:\n', output_files(i).name);
            fprintf('  最小值: %.4e kg m^-2 s^-1\n', min(vimd_sample(:)));
            fprintf('  最大值: %.4e kg m^-2 s^-1\n', max(vimd_sample(:)));
            fprintf('  平均值: %.4e kg m^-2 s^-1\n', mean(vimd_sample(:)));
            fprintf('  标准差: %.4e kg m^-2 s^-1\n', std(vimd_sample(:)));
        catch ME
            fprintf('  无法读取文件 %s: %s\n', output_files(i).name, ME.message);
        end
    end
end

fprintf('\n===== 处理完成 =====\n');