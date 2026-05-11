load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/kf_filter.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"

begin

   ; 读取输入文件
   f = addfile("GPM_anomaly_6hourly_20220901_20230630.nc","r")
   
   ; 读取变量
   precip_anom = f->precipitation_anomaly
   lat = f->lat
   lon = f->lon
   time = f->time
   delete(f)
   
   ; 检查维度顺序
   printVarSummary(precip_anom)
   
   ; 确保变量有正确的维度和坐标
   precip_anom!0 = "time"
   precip_anom!1 = "lon" 
   precip_anom!2 = "lat"
   precip_anom&time = time
   precip_anom&lat = lat
   precip_anom&lon = lon
   
   ; 转换为float类型（确保数据类型一致）
   precip_anom_float = tofloat(precip_anom)
   copy_VarMeta(precip_anom, precip_anom_float)
   printVarSummary(precip_anom_float)
   
   ; 创建输出数组
   precip_filt = new((/dimsizes(time), dimsizes(lon), dimsizes(lat)/), float)
   precip_filt!0 = "time"
   precip_filt!1 = "lon"
   precip_filt!2 = "lat"
   precip_filt&time = time
   precip_filt&lat = lat
   precip_filt&lon = lon
   precip_filt@long_name = "Kelvin-filtered 6-hourly precipitation anomaly"
   precip_filt@units = "mm"
   precip_filt@_FillValue = -9999.9
   
   ; 设置Kelvin波滤波参数
   tMin = 2.5     ; 最小周期（天）
   tMax = 17.0    ; 最大周期（天）
   kMin = 1       ; 最小波数
   kMax = 14      ; 最大波数
   hMin = 8.0     ; 最小等效深度（米）
   hMax = 90.0    ; 最大等效深度（米）
   waveName = "Kelvin"
   obsPerDay = 4  ; 6小时数据，一天4个观测值
   
   print("开始Kelvin波滤波处理...")
   print("时间维度大小: " + dimsizes(time))
   print("经度维度大小: " + dimsizes(lon))
   print("纬度维度大小: " + dimsizes(lat))
   print("观测频率: " + obsPerDay + " 次/天")
   print("滤波参数: 周期 " + tMin + "-" + tMax + " 天, 波数 " + kMin + "-" + kMax + ", 等效深度 " + hMin + "-" + hMax + " m")
   
   ; 对每个纬度进行Kelvin波滤波
   do i = 0, dimsizes(lat)-1
      if (mod(i, 50) .eq. 0) then
         print("正在处理纬度: " + lat(i) + " (" + (i+1) + "/" + dimsizes(lat) + ")")
      end if
      
      ; 提取当前纬度的数据（维度顺序：时间, 经度）
      data_slice = precip_anom_float(time|:, lon|:, lat|i)
      
      ; 应用Kelvin波滤波
      precip_filt(:,:,i) = kf_filter(data_slice, obsPerDay, \
                                      tMin, tMax, kMin, kMax, \
                                      hMin, hMax, waveName)
      
      delete(data_slice)
   end do
   
   print("Kelvin波滤波完成!")
   
   ; 复制全局属性
   precip_filt@filter_info = "Kelvin波滤波: 周期" + tMin + "-" + tMax + "天, 波数" + kMin + "-" + kMax + ", 等效深度" + hMin + "-" + hMax + "m"
   precip_filt@original_data = "GPM_anomaly_6hourly_20220901_20230630.nc"
   precip_filt@filter_method = "kf_filter函数"
   precip_filt@obsPerDay = obsPerDay
   
   ; 打印输出变量信息
   printVarSummary(precip_filt)
   
   ; 检查滤波结果
   printMinMax(precip_filt, 0)
   
   ; 设置输出文件选项
   setfileoption("nc", "Format", "NetCDF4Classic")
   
   ; 创建输出文件
   outfile = "GPM_anomaly_6hourly_for_Kelvin_20220901_20230630.nc"
   system("rm -f " + outfile)  ; 删除已存在的文件
   a = addfile(outfile, "c")
   
   ; 添加全局属性
   a@title = "GPM 6-hourly Precipitation Anomaly Filtered for Kelvin Wave (20S-20N)"
   a@source = "GPM IMERG Half-Hourly Data with Kelvin wave filtering"
   a@date_created = systemfunc("date -u +'%Y-%m-%d %H:%M:%S'")
   a@latitude_range = "20S to 20N"
   a@time_coverage_start = "20220901T00:00:00Z"
   a@time_coverage_end = "20230630T18:00:00Z"
   a@temporal_resolution = "6 hours"
   a@spatial_resolution = "0.1 degree"
   a@units = "mm"
   a@long_name = "Kelvin-filtered 6-hourly precipitation anomaly"
   a@filter_method = "kf_filter: Kelvin wave bandpass filter (2.5-17 day, wavenumber 1-14, phase speed 8-90 m/s)"
   a@filter_parameters = "tMin=" + tMin + ", tMax=" + tMax + ", kMin=" + kMin + ", kMax=" + kMax + ", hMin=" + hMin + ", hMax=" + hMax
   a@original_file = "GPM_anomaly_6hourly_20220901_20230630.nc"
   a@creation_date = systemfunc("date")
   
   ; 定义维度
   dimNames = (/"time", "lon", "lat"/)
   dimSizes = (/dimsizes(time), dimsizes(lon), dimsizes(lat)/)
   dimUnlim = (/True, False, False/)
   filedimdef(a, dimNames, dimSizes, dimUnlim)
   
   ; 定义变量和属性
   filevardef(a, "time", typeof(time), "time")
   filevardef(a, "lon", typeof(lon), "lon")
   filevardef(a, "lat", typeof(lat), "lat")
   filevardef(a, "precipitation_anomaly_kelvin", typeof(precip_filt), dimNames)
   
   ; 添加变量属性
   a->time@long_name = "Time"
   a->time@units = "days since 0000-01-01 00:00:00"
   a->time@calendar = "standard"
   
   a->lon@long_name = "Longitude"
   a->lon@units = "degrees_east"
   a->lon@actual_range = (/min(lon), max(lon)/)
   
   a->lat@long_name = "Latitude"
   a->lat@units = "degrees_north"  ; 修正这里：将a@lat@units改为a->lat@units
   a->lat@actual_range = (/min(lat), max(lat)/)
   
   a->precipitation_anomaly_kelvin@long_name = "Kelvin-filtered 6-hourly precipitation anomaly"
   a->precipitation_anomaly_kelvin@units = "mm"
   a->precipitation_anomaly_kelvin@_FillValue = -9999.9
   a->precipitation_anomaly_kelvin@filter_info = "Kelvin wave bandpass filter: 2.5-17 days, wavenumber 1-14, phase speed 8-90 m/s"
   a->precipitation_anomaly_kelvin@obsPerDay = obsPerDay
   a->precipitation_anomaly_kelvin@temporal_filter_range = tMin + "-" + tMax + " days"
   a->precipitation_anomaly_kelvin@wavenumber_filter_range = kMin + "-" + kMax
   a->precipitation_anomaly_kelvin@phase_speed_filter_range = hMin + "-" + hMax + " m"
   
   ; 写入变量
   a->time = (/time/)
   a->lon = (/lon/)
   a->lat = (/lat/)
   a->precipitation_anomaly_kelvin = (/precip_filt/)
   
   print("输出文件已保存: " + outfile)
   print("处理完成!")
   
end