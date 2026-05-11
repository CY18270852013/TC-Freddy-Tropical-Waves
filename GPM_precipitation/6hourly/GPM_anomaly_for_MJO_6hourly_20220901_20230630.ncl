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
   
   ; 创建输出数组
   precip_filt = new((/dimsizes(time), dimsizes(lon), dimsizes(lat)/), float)
   precip_filt!0 = "time"
   precip_filt!1 = "lon"
   precip_filt!2 = "lat"
   precip_filt&time = time
   precip_filt&lat = lat
   precip_filt&lon = lon
   precip_filt@long_name = "MJO-filtered 6-hourly precipitation anomaly"
   precip_filt@units = "mm"
   precip_filt@_FillValue = -9999.9
   
   ; 设置MJO滤波参数
   tMin = 30    ; 最小周期（天）
   tMax = 96    ; 最大周期（天）
   kMin = 1     ; 最小波数
   kMax = 9     ; 最大波数
   hMin = 0.01  ; 最小水平相速度
   hMax = 120   ; 最大水平相速度
   waveName = "MJO"
   obsPerDay = 4  ; 6小时数据，一天4个观测值
   
   print("开始MJO滤波处理...")
   print("时间维度大小: " + dimsizes(time))
   print("经度维度大小: " + dimsizes(lon))
   print("纬度维度大小: " + dimsizes(lat))
   print("观测频率: " + obsPerDay + " 次/天")
   
   ; 对每个纬度进行MJO滤波
   do i = 0, dimsizes(lat)-1
      if (mod(i, 50) .eq. 0) then
         print("正在处理纬度: " + lat(i) + " (" + (i+1) + "/" + dimsizes(lat) + ")")
      end if
      
      ; 提取当前纬度的数据（维度顺序：时间, 经度）
      data_slice = precip_anom(time|:, lon|:, lat|i)
      
      ; 应用MJO滤波
      precip_filt(:,:,i) = kf_filter(data_slice, obsPerDay, \
                                      tMin, tMax, kMin, kMax, \
                                      hMin, hMax, waveName)
      
      delete(data_slice)
   end do
   
   print("MJO滤波完成!")
   
   ; 复制全局属性
   precip_filt@filter_info = "MJO滤波: 周期" + tMin + "-" + tMax + "天, 波数" + kMin + "-" + kMax
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
   outfile = "GPM_anomaly_6hourly_for_MJO_20220901_20230630.nc"
   system("rm -f " + outfile)  ; 删除已存在的文件
   a = addfile(outfile, "c")
   
   ; 添加全局属性
   a@title = "GPM 6-hourly Precipitation Anomaly Filtered for MJO (20S-20N)"
   a@source = "GPM IMERG Half-Hourly Data with MJO filtering"
   a@date_created = systemfunc("date -u +'%Y-%m-%d %H:%M:%S'")
   a@latitude_range = "20S to 20N"
   a@time_coverage_start = "20220901T00:00:00Z"
   a@time_coverage_end = "20230630T18:00:00Z"
   a@temporal_resolution = "6 hours"
   a@spatial_resolution = "0.1 degree"
   a@units = "mm"
   a@long_name = "MJO-filtered 6-hourly precipitation anomaly"
   a@filter_method = "kf_filter: 30-96 day bandpass, wavenumber 1-9"
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
   filevardef(a, "precipitation_anomaly_mjo", typeof(precip_filt), dimNames)
   
   ; 添加变量属性
   a->time@long_name = "Time"
   a->time@units = "days since 0000-01-01 00:00:00"
   a->time@calendar = "standard"
   
   a->lon@long_name = "Longitude"
   a->lon@units = "degrees_east"
   a->lon@actual_range = (/min(lon), max(lon)/)
   
   a->lat@long_name = "Latitude"
   a->lat@units = "degrees_north"
   a->lat@actual_range = (/min(lat), max(lat)/)
   
   a->precipitation_anomaly_mjo@long_name = "MJO-filtered 6-hourly precipitation anomaly"
   a->precipitation_anomaly_mjo@units = "mm"
   a->precipitation_anomaly_mjo@_FillValue = -9999.9
   a->precipitation_anomaly_mjo@filter_info = "MJO bandpass filter: 30-96 days, wavenumber 1-9"
   a->precipitation_anomaly_mjo@obsPerDay = obsPerDay
   
   ; 写入变量
   a->time = (/time/)
   a->lon = (/lon/)
   a->lat = (/lat/)
   a->precipitation_anomaly_mjo = (/precip_filt/)
   
   print("输出文件已保存: " + outfile)
   print("处理完成!")
   
end