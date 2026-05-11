load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/kf_filter.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"

begin

   ; 设置输入输出文件路径
   pathIn = "divergence_anomaly_6hourly_20220101_20231231.nc"
   pathOut = "divergence_anomaly_for_MJO_6hourly_20220101_20231231.nc"
   
   ; 读取数据
   f = addfile(pathIn, "r")
   div_anom = f->divergence_anomaly
   lat = f->latitude
   lon = f->longitude
   time = f->time
   delete(f)

   ; 设置正确的维度顺序和坐标变量
   ; 注意：kf_filter函数需要特定的维度名称
   div_anom!0 = "time"
   div_anom!1 = "lat"    ; 改名为lat，因为kf_filter需要这个名称
   div_anom!2 = "lon"    ; 改名为lon，因为kf_filter需要这个名称
   div_anom&time = time
   div_anom&lat = lat
   div_anom&lon = lon
   
   ; 重命名坐标变量以便匹配
   lat@long_name = "Latitude"
   lat@standard_name = "latitude"
   lat@units = "degrees_north"
   
   lon@long_name = "Longitude"
   lon@standard_name = "longitude"
   lon@units = "degrees_east"
   
   ; 转换为float类型并复制元数据
   div_anom_float = tofloat(div_anom)
   copy_VarMeta(div_anom, div_anom_float)
   
   printVarSummary(div_anom_float)

   ; 创建输出数组
   divergence_anomaly_mjo = new((/dimsizes(time), dimsizes(lat), dimsizes(lon)/), float)

   ; 设置MJO滤波参数
   tMin = 30      ; 最小周期（天）
   tMax = 96      ; 最大周期（天）
   kMin = 1       ; 最小波数
   kMax = 9       ; 最大波数
   hMin = 0.01    ; 最小等效深度（米）
   hMax = 120     ; 最大等效深度（米）
   waveName = "MJO"  ; 波动类型
   obsPerDay = 4     ; 每天观测次数（6小时数据，所以是4次）

   print("开始滤波...")
   
   ; 对每个纬度进行滤波
   do i = 0, dimsizes(lat)-1
      ; 提取每个纬度的数据（时间×经度）
      ; 注意：kf_filter要求维度顺序为(time, lon)
      lat_slice = div_anom_float(time|:, lat|i, lon|:)
      
      ; 确保维度名称正确
      lat_slice!0 = "time"
      lat_slice!1 = "lon"
      lat_slice&time = time
      lat_slice&lon = lon
      
      ; 应用MJO滤波
      filtered_slice = kf_filter(lat_slice, obsPerDay, \
                                 tMin, tMax, kMin, kMax, hMin, hMax, waveName)
      
      ; 将滤波后的数据存回数组
      divergence_anomaly_mjo(:, i, :) = filtered_slice
   end do
   
   ; 恢复原始维度名称
   divergence_anomaly_mjo!0 = "time"
   divergence_anomaly_mjo!1 = "latitude"
   divergence_anomaly_mjo!2 = "longitude"
   divergence_anomaly_mjo&time = time
   divergence_anomaly_mjo&latitude = lat
   divergence_anomaly_mjo&longitude = lon
   
   ; 复制原始数据的元数据
   copy_VarAtts(div_anom, divergence_anomaly_mjo)
   
   ; 更新描述信息
   divergence_anomaly_mjo@description = "MJO-filtered divergence anomaly (30-96 day bandpass)"
   divergence_anomaly_mjo@filter_method = "kf_filter for MJO extraction"
   divergence_anomaly_mjo@filter_parameters = "tMin=30, tMax=96, kMin=1, kMax=9, hMin=0.01, hMax=120"
   divergence_anomaly_mjo@obsPerDay = obsPerDay
   divergence_anomaly_mjo@long_name = "MJO-filtered Divergence Anomaly"
   divergence_anomaly_mjo@standard_name = "divergence_of_wind_anomaly_mjo"

   printVarSummary(divergence_anomaly_mjo)

   ; 设置输出文件选项
   setfileoption("nc", "Format", "NetCDF4Classic")

   ; 创建输出文件
   system("rm -f " + pathOut)  ; 如果文件已存在则删除
   fo = addfile(pathOut, "c")
   
   ; 定义文件属性
   fo@title = "ERA5 MJO-filtered Divergence Anomaly at 850 hPa"
   fo@source = "ERA5 reanalysis"
   fo@institution = "European Centre for Medium-Range Weather Forecasts"
   fo@history = "Created by NCL kf_filter on " + systemfunc("date")
   fo@reference_period = "2009-2023"
   fo@target_period = "2022-01-01 to 2023-12-31"
   fo@time_resolution = "6-hourly"
   fo@spatial_resolution = "0.5 degree x 0.5 degree"
   fo@latitude_range = "10N to 30S"
   fo@longitude_range = "0 to 359.5E"
   fo@method = "15-year mean removed + FFT filtering (first 3 harmonics) + MJO filtering (kf_filter)"
   fo@author = "Freddy ChenYong"
   fo@purpose = "Study environmental characteristics and life cycle mechanisms of Tropical Cyclone Freddy in the South Indian Ocean"
   fo@processing_script = "divergence_anomaly_for_MJO_6hourly_20220101_20231231.ncl"
   fo@filter_applied = "kf_filter for MJO (30-96 days)"
   fo@notes = "Filtered using kf_filter.ncl with parameters: tMin=30, tMax=96, kMin=1, kMax=9, hMin=0.01, hMax=120, obsPerDay=4"
   
   ; 定义维度
   dimNames = (/"time", "latitude", "longitude"/)
   dimSizes = (/dimsizes(time), dimsizes(lat), dimsizes(lon)/)
   dimUnlim = (/True, False, False/)  ; 时间维度设为无限制
   filedimdef(fo, dimNames, dimSizes, dimUnlim)
   
   ; 定义坐标变量
   filevardef(fo, "time", typeof(time), "time")
   filevardef(fo, "latitude", typeof(lat), "latitude")
   filevardef(fo, "longitude", typeof(lon), "longitude")
   filevardef(fo, "divergence_anomaly_mjo", typeof(divergence_anomaly_mjo), dimNames)
   
   ; 定义坐标变量属性
   time@long_name = "Time"
   time@units = "days since 0000-01-01 00:00:00"
   time@calendar = "proleptic_gregorian"
   time@standard_name = "time"
   
   lat@long_name = "Latitude"
   lat@units = "degrees_north"
   lat@standard_name = "latitude"
   
   lon@long_name = "Longitude"
   lon@units = "degrees_east"
   lon@standard_name = "longitude"
   
   ; 定义主变量属性
   divergence_anomaly_mjo@_FillValue = -999.0  ; 设置新的FillValue
   divergence_anomaly_mjo@long_name = "MJO-filtered Divergence Anomaly"
   divergence_anomaly_mjo@units = "s^-1"
   divergence_anomaly_mjo@standard_name = "divergence_of_wind_anomaly_mjo"
   divergence_anomaly_mjo@pressure_level = "850 hPa"
   divergence_anomaly_mjo@description = "MJO-filtered divergence anomaly (30-96 day bandpass)"
   divergence_anomaly_mjo@filter_method = "kf_filter for MJO extraction"
   divergence_anomaly_mjo@filter_parameters = "tMin=30, tMax=96, kMin=1, kMax=9, hMin=0.01, hMax=120"
   divergence_anomaly_mjo@obsPerDay = obsPerDay
   
   ; 写入属性
   filevarattdef(fo, "time", time)
   filevarattdef(fo, "latitude", lat)
   filevarattdef(fo, "longitude", lon)
   filevarattdef(fo, "divergence_anomaly_mjo", divergence_anomaly_mjo)
   
   ; 写入数据
   fo->time = time
   fo->latitude = lat
   fo->longitude = lon
   fo->divergence_anomaly_mjo = divergence_anomaly_mjo
   
   print("滤波完成，结果已保存至: " + pathOut)
   
   ; 输出一些统计信息
   print("原始数据统计:")
   print("  Min: " + min(div_anom_float))
   print("  Max: " + max(div_anom_float))
   print("  Mean: " + avg(div_anom_float))
   
   print("MJO滤波后数据统计:")
   print("  Min: " + min(divergence_anomaly_mjo))
   print("  Max: " + max(divergence_anomaly_mjo))
   print("  Mean: " + avg(divergence_anomaly_mjo))
   
end