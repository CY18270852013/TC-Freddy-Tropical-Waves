load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/kf_filter.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"

begin

   ; 设置输入输出文件路径
   pathIn = "VIMD_anomaly_6hourly_20220101_20231231.nc"
   pathOut = "VIMD_anomaly_for_MJO_6hourly_20220101_20231231.nc"
   
   ; 读取数据
   f = addfile(pathIn, "r")
   vimd_anomaly = f->vimd_anomaly
   lat = f->latitude
   lon = f->longitude
   time = f->time
   delete(f)
   
   ; 处理NaN值（原数据中的_FillValue为-nan）
   if (any(isnan_ieee(vimd_anomaly))) then
       vimd_anomaly@_FillValue = default_fillvalue(typeof(vimd_anomaly))
       replace_ieeenan(vimd_anomaly, vimd_anomaly@_FillValue, 0)
   end if
   
   ; 确保正确的维度顺序和坐标
   vimd_anomaly!0 = "time"
   vimd_anomaly!1 = "latitude"
   vimd_anomaly!2 = "longitude"
   vimd_anomaly&time = time
   vimd_anomaly&latitude = lat
   vimd_anomaly&longitude = lon
   
   ; 转换为float类型（如果需要）
   vimd_anomaly_float = tofloat(vimd_anomaly)
   copy_VarMeta(vimd_anomaly, vimd_anomaly_float)
   printVarSummary(vimd_anomaly_float)
   
   ; 创建输出数组
   vimd_filt = new((/dimsizes(time), dimsizes(lat), dimsizes(lon)/), float)
   
   ; 设置MJO滤波参数
   tMin = 30      ; 最小周期（天）
   tMax = 96      ; 最大周期（天）
   kMin = 1       ; 最小波数
   kMax = 9       ; 最大波数
   hMin = 0.01    ; 最小等效深度（米）
   hMax = 120     ; 最大等效深度（米）
   waveName = "MJO" ; 波动名称
   obsPerDay = 4  ; 6小时数据，一天4次观测
   
   print("开始滤波...")
   
   ; 对每个纬度进行滤波
   do i = 0, dimsizes(lat)-1
      print("正在处理纬度: " + lat(i) + " (" + (i+1) + "/" + dimsizes(lat) + ")")
      
      ; 提取当前纬度的数据（时间×经度）
      ; 使用正确的维度顺序：time × longitude
      data_slice = vimd_anomaly_float(time|:, latitude|i, longitude|:)
      
      ; 为数据切片设置正确的维度名称
      ; kf_filter期望维度名为"time"和"lon"，所以我们需要重命名
      data_slice!0 = "time"
      data_slice!1 = "lon"
      
      ; 复制坐标变量
      data_slice&lon = lon
      
      ; 应用kf_filter
      filtered_slice = kf_filter(data_slice, obsPerDay, \
                                 tMin, tMax, kMin, kMax, \
                                 hMin, hMax, waveName)
      
      ; 将结果赋值到正确位置
      vimd_filt(:, i, :) = filtered_slice
      
      ; 清理内存
      delete([/data_slice, filtered_slice/])
   end do
   
   ; 为输出数据设置正确的元数据
   vimd_filt!0 = "time"
   vimd_filt!1 = "latitude"
   vimd_filt!2 = "longitude"
   vimd_filt&time = time
   vimd_filt&latitude = lat
   vimd_filt&longitude = lon
   
   ; 添加属性
   vimd_filt@long_name = "Filtered Vertically Integrated Moisture Divergence Anomaly for MJO"
   vimd_filt@description = "VIMD anomaly filtered to retain MJO signals (30-96 days, wavenumbers 1-9)"
   vimd_filt@units = "kg m^-2 s^-1"
   vimd_filt@_FillValue = default_fillvalue("float")
   
   printVarSummary(vimd_filt)
   
   ; 设置输出文件选项
   setfileoption("nc", "Format", "NetCDF4Classic")
   
   ; 创建输出文件
   fout = addfile(pathOut, "c")
   
   ; 定义文件属性
   fout@title = "Filtered Vertically Integrated Moisture Divergence (VIMD) Anomaly for MJO"
   fout@source = "Filtered from VIMD_anomaly_6hourly_20220101_20231231.nc"
   fout@history = "Created: " + systemfunc("date")
   fout@Conventions = "CF-1.7"
   fout@base_period = "2009-01-01 to 2023-12-31"
   fout@target_period = "2022-01-01 to 2023-12-31"
   fout@temporal_resolution = "6-hourly"
   fout@spatial_resolution = "0.5x0.5 degree"
   fout@latitude_range = "10N to 30S"
   fout@longitude_range = "0 to 360"
   fout@filter_method = "kf_filter for MJO (30-96 days, wavenumbers 1-9)"
   fout@author = "For research on Tropical Cyclone Freddy (2023)"
   
   ; 写入维度变量
   fout->longitude = lon
   fout->latitude = lat
   fout->time = time
   
   ; 写入滤波后的数据
   fout->vimd_anomaly_mjo = vimd_filt
   
   print("滤波完成！结果已保存到: " + pathOut)
   
end