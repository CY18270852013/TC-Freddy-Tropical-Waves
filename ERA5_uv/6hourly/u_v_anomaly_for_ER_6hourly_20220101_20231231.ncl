load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/kf_filter.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"

begin

   ; 设置输入输出文件路径
   pathIn = "u_v_anomaly_6hourly_20220101_20231231.nc"
   pathOut = "u_v_anomaly_for_ER_6hourly_20220101_20231231.nc"
   
   ; 读取数据
   f = addfile(pathIn, "r")
   u_anomaly = f->u_anomaly
   v_anomaly = f->v_anomaly
   lat = f->latitude
   lon = f->longitude
   time = f->time
   
   printVarSummary(u_anomaly)
   printVarSummary(v_anomaly)
   
   ; 确保变量有正确的维度和坐标
   u_anomaly!0 = "time"
   u_anomaly!1 = "lat"  ; 注意：kf_filter要求维度名为lat，不是latitude
   u_anomaly!2 = "lon"  ; 注意：kf_filter要求维度名为lon，不是longitude
   u_anomaly&time = time
   u_anomaly&lat = lat
   u_anomaly&lon = lon
   
   v_anomaly!0 = "time"
   v_anomaly!1 = "lat"  ; 注意：kf_filter要求维度名为lat，不是latitude
   v_anomaly!2 = "lon"  ; 注意：kf_filter要求维度名为lon，不是longitude
   v_anomaly&time = time
   v_anomaly&lat = lat
   v_anomaly&lon = lon
   
   ; 转换为float类型（如果还不是）
   u_anomaly_float = tofloat(u_anomaly)
   v_anomaly_float = tofloat(v_anomaly)
   copy_VarMeta(u_anomaly, u_anomaly_float)
   copy_VarMeta(v_anomaly, v_anomaly_float)
   
   ; 创建滤波后的数组
   u_anomaly_er = new((/dimsizes(time), dimsizes(lat), dimsizes(lon)/), float)
   v_anomaly_er = new((/dimsizes(time), dimsizes(lat), dimsizes(lon)/), float)
   
   ; 设置ER波滤波参数
   tMin = 9.7      ; 最小周期（天）
   tMax = 48.0     ; 最大周期（天）
   kMin = -1       ; 最小波数（负值表示西向波）
   kMax = -10      ; 最大波数（负值表示西向波）
   hMin = 5.0      ; 最小高度（km）
   hMax = 90.0     ; 最大高度（km）
   waveName = "ER"
   obsPerDay = 4   ; 6小时数据，所以每天4个观测
   
   print("开始对u_anomaly进行ER波滤波...")
   ; 对每个纬度进行u分量滤波
   do i = 0, dimsizes(lat)-1
      ; 提取每个纬度的二维数组（时间, 经度）
      ; 注意：kf_filter函数要求维度名为"time"和"lon"
      u_temp = u_anomaly_float(time|:, lat|i, lon|:)
      
      ; 确保维度名称正确
      u_temp!0 = "time"
      u_temp!1 = "lon"
      u_temp&time = time
      u_temp&lon = lon
      
      ; 进行滤波
      u_filtered = kf_filter(u_temp, obsPerDay, \
                             tMin, tMax, kMin, kMax, \
                             hMin, hMax, waveName)
      
      ; 将结果存回三维数组
      u_anomaly_er(:, i, :) = u_filtered
   end do
   
   print("开始对v_anomaly进行ER波滤波...")
   ; 对每个纬度进行v分量滤波
   do i = 0, dimsizes(lat)-1
      ; 提取每个纬度的二维数组（时间, 经度）
      v_temp = v_anomaly_float(time|:, lat|i, lon|:)
      
      ; 确保维度名称正确
      v_temp!0 = "time"
      v_temp!1 = "lon"
      v_temp&time = time
      v_temp&lon = lon
      
      ; 进行滤波
      v_filtered = kf_filter(v_temp, obsPerDay, \
                             tMin, tMax, kMin, kMax, \
                             hMin, hMax, waveName)
      
      ; 将结果存回三维数组
      v_anomaly_er(:, i, :) = v_filtered
   end do
   
   ; 复制元数据
   copy_VarMeta(u_anomaly, u_anomaly_er)
   copy_VarMeta(v_anomaly, v_anomaly_er)
   
   ; 修改变量名和长名
   u_anomaly_er@long_name = "U component wind anomaly (ER filtered)"
   u_anomaly_er@standard_name = "eastward_wind_anomaly_er"
   
   v_anomaly_er@long_name = "V component wind anomaly (ER filtered)"
   v_anomaly_er@standard_name = "northward_wind_anomaly_er"
   
   ; 恢复维度名称为原始名称以便输出
   u_anomaly_er!0 = "time"
   u_anomaly_er!1 = "latitude"
   u_anomaly_er!2 = "longitude"
   u_anomaly_er&time = time
   u_anomaly_er&latitude = lat
   u_anomaly_er&longitude = lon
   
   v_anomaly_er!0 = "time"
   v_anomaly_er!1 = "latitude"
   v_anomaly_er!2 = "longitude"
   v_anomaly_er&time = time
   v_anomaly_er&latitude = lat
   v_anomaly_er&longitude = lon
   
   printVarSummary(u_anomaly_er)
   printVarSummary(v_anomaly_er)
   
   ; 创建输出文件
   setfileoption("nc", "Format", "NetCDF4Classic")
   
   ; 删除已存在的输出文件（如果存在）
   system("rm -f " + pathOut)
   
   a = addfile(pathOut, "c")
   
   ; 设置文件属性
   fAtt = True
   fAtt@title = "ERA5 u and v wind anomalies at 850 hPa (ER filtered)"
   fAtt@source = "ERA5 reanalysis"
   fAtt@pressure_level = "850 hPa"
   fAtt@time_resolution = "6-hourly"
   fAtt@latitude_range = "10N to 30S"
   fAtt@longitude_range = "0 to 359.5E"
   fAtt@time_coverage_start = "2022-01-01 00:00:00"
   fAtt@time_coverage_end = "2023-12-31 18:00:00"
   fAtt@climatology_period = "2009-01-01 to 2023-12-31"
   fAtt@method = "15-year mean removed + FFT filtering (first 3 harmonics) + ER wave filtering (9.7-48 days)"
   fAtt@created_by = "NCL script for Freddy tropical cyclone research"
   fAtt@creation_date = systemfunc("date")
   fAtt@filter_method = "kf_filter with ER wave parameters"
   fAtt@filter_parameters = "tMin=9.7, tMax=48.0, kMin=-1, kMax=-10, hMin=5.0, hMax=90.0, obsPerDay=4"
   fileattdef(a, fAtt)
   
   ; 定义维度
   dimNames = (/"time", "latitude", "longitude"/)
   dimSizes = (/dimsizes(time), dimsizes(lat), dimsizes(lon)/)
   dimUnlim = (/False, False, False/)
   filedimdef(a, dimNames, dimSizes, dimUnlim)
   
   ; 定义变量和写入变量
   filevardef(a, "time", typeof(time), "time")
   filevardef(a, "latitude", typeof(lat), "latitude")
   filevardef(a, "longitude", typeof(lon), "longitude")
   filevardef(a, "u_anomaly_er", typeof(u_anomaly_er), (/"time", "latitude", "longitude"/))
   filevardef(a, "v_anomaly_er", typeof(v_anomaly_er), (/"time", "latitude", "longitude"/))
   
   ; 写入变量属性
   filevarattdef(a, "time", time)
   filevarattdef(a, "latitude", lat)
   filevarattdef(a, "longitude", lon)
   filevarattdef(a, "u_anomaly_er", u_anomaly_er)
   filevarattdef(a, "v_anomaly_er", v_anomaly_er)
   
   ; 写入变量数据
   a->time = time
   a->latitude = lat
   a->longitude = lon
   a->u_anomaly_er = u_anomaly_er
   a->v_anomaly_er = v_anomaly_er
   
   print("滤波完成！结果已保存到: " + pathOut)
   
end