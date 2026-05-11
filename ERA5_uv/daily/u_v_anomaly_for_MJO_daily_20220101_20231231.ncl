load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/kf_filter.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"

begin

  ; 设置输入输出文件路径
  pathIn = "u_v_anomaly_daily_20220101_20231231.nc"
  pathOut = "u_v_anomaly_for_MJO_daily_20220101_20231231.nc"
  
  ; 读取数据文件
  f = addfile(pathIn, "r")
  
  ; 读取变量数据
  u_anomaly = f->u_anomaly
  v_anomaly = f->v_anomaly
  lat = f->latitude
  lon = f->longitude
  time = f->time
  
  ; 检查数据维度顺序
  printVarSummary(u_anomaly)
  printVarSummary(v_anomaly)
  
  ; 为变量添加维度名称和坐标
  u_anomaly!0 = "time"
  u_anomaly!1 = "lat"
  u_anomaly!2 = "lon"
  u_anomaly&time = time
  u_anomaly&lat = lat
  u_anomaly&lon = lon
  
  v_anomaly!0 = "time"
  v_anomaly!1 = "lat"
  v_anomaly!2 = "lon"
  v_anomaly&time = time
  v_anomaly&lat = lat
  v_anomaly&lon = lon
  
  ; 转换为浮点型（如果还不是）
  u_anom_float = tofloat(u_anomaly)
  v_anom_float = tofloat(v_anomaly)
  
  ; 复制元数据
  copy_VarMeta(u_anomaly, u_anom_float)
  copy_VarMeta(v_anomaly, v_anom_float)
  
  ; 创建滤波后的数组
  u_filt = new((/dimsizes(time), dimsizes(lat), dimsizes(lon)/), float)
  v_filt = new((/dimsizes(time), dimsizes(lat), dimsizes(lon)/), float)
  
  ; 设置MJO滤波参数
  tMin = 30     ; 最小周期（天）
  tMax = 96     ; 最大周期（天）
  kMin = 1      ; 最小波数
  kMax = 9      ; 最大波数
  hMin = 0.01   ; 最小赤道变形半径
  hMax = 120    ; 最大赤道变形半径
  waveName = "MJO"
  obsPerDay = 1 ; 每日观测（日数据）
  
  print("开始滤波处理...")
  print("处理u_anomaly变量...")
  
  ; 对u_anomaly进行滤波（对每个纬度）
  do i = 0, dimsizes(lat)-1
    ; 提取每个纬度的二维数组（时间×经度）
    ; 注意：kf_filter函数要求第一维是时间
    u_filt(:, i, :) = kf_filter(u_anom_float(time|:, lat|i, lon|:), obsPerDay, \
                               tMin, tMax, kMin, kMax, hMin, hMax, waveName)
  end do
  
  print("处理v_anomaly变量...")
  
  ; 对v_anomaly进行滤波（对每个纬度）
  do i = 0, dimsizes(lat)-1
    v_filt(:, i, :) = kf_filter(v_anom_float(time|:, lat|i, lon|:), obsPerDay, \
                               tMin, tMax, kMin, kMax, hMin, hMax, waveName)
  end do
  
  ; 复制元数据到滤波后的变量
  copy_VarMeta(u_anomaly, u_filt)
  copy_VarMeta(v_anomaly, v_filt)
  
  ; 修改变量名和属性
  u_filt@long_name = "Daily eastward wind anomaly at 850 hPa (MJO filtered)"
  u_filt@filter_info = "MJO filter: 30-96 days, wavenumbers 1-9"
  u_filt@processing = "MJO bandpass filtering using kf_filter"
  
  v_filt@long_name = "Daily northward wind anomaly at 850 hPa (MJO filtered)"
  v_filt@filter_info = "MJO filter: 30-96 days, wavenumbers 1-9"
  v_filt@processing = "MJO bandpass filtering using kf_filter"
  
  ; 设置输出文件格式
  setfileoption("nc", "Format", "NetCDF4Classic")
  
  ; 创建输出文件
  system("/bin/rm -f " + pathOut)  ; 删除已存在的文件
  fo = addfile(pathOut, "c")
  
  ; 定义文件维度
  filedimdef(fo, (/"time", "lat", "lon"/), \
             (/dimsizes(time), dimsizes(lat), dimsizes(lon)/), \
             (/False, False, False/))
  
  ; 定义文件变量
  filevardef(fo, "time", typeof(time), "time")
  filevardef(fo, "lat", typeof(lat), "lat")
  filevardef(fo, "lon", typeof(lon), "lon")
  filevardef(fo, "u_anomaly_mjo", typeof(u_filt), (/"time", "lat", "lon"/))
  filevardef(fo, "v_anomaly_mjo", typeof(v_filt), (/"time", "lat", "lon"/))
  
  ; 复制变量属性
  filevarattdef(fo, "time", time)
  filevarattdef(fo, "lat", lat)
  filevarattdef(fo, "lon", lon)
  filevarattdef(fo, "u_anomaly_mjo", u_filt)
  filevarattdef(fo, "v_anomaly_mjo", v_filt)
  
  ; 写入数据
  fo->time = (/time/)
  fo->lat = (/lat/)
  fo->lon = (/lon/)
  fo->u_anomaly_mjo = (/u_filt/)
  fo->v_anomaly_mjo = (/v_filt/)
  
  ; 添加全局属性
  globalAtt = True
  globalAtt@title = "Daily mean wind anomaly at 850 hPa from ERA5 (MJO filtered)"
  globalAtt@source = "ERA5 reanalysis"
  globalAtt@institution = "European Centre for Medium-Range Weather Forecasts"
  globalAtt@history = "Created by NCL on " + systemfunc("date")
  globalAtt@Conventions = "CF-1.7"
  globalAtt@creation_date = systemfunc("date")
  globalAtt@time_coverage_start = "2022-01-01"
  globalAtt@time_coverage_end = "2023-12-31"
  globalAtt@latitude_range = "30.0 to -30.0 degrees_north"
  globalAtt@longitude_range = "0.0 to 359.5 degrees_east"
  globalAtt@pressure_level = "850 hPa"
  globalAtt@spatial_resolution = "0.5 x 0.5 degrees"
  globalAtt@temporal_resolution = "daily mean"
  globalAtt@filtering_method = "kf_filter: MJO bandpass (30-96 days, wavenumbers 1-9)"
  globalAtt@original_processing = "15-year mean removed + FFT filtering (first 3 harmonics)"
  globalAtt@reference_period = "2009-01-01 to 2023-12-31"
  globalAtt@note = "Filtered to retain MJO signal only"
  
  fileattdef(fo, globalAtt)
  
  print("滤波完成！")
  print("输出文件: " + pathOut)
  print("输出变量:")
  print("  u_anomaly_mjo: Daily eastward wind anomaly at 850 hPa (MJO filtered)")
  print("  v_anomaly_mjo: Daily northward wind anomaly at 850 hPa (MJO filtered)")
  
  ; 打印滤波后变量的统计信息
  print("")
  print("滤波后变量统计信息:")
  printVarSummary(u_filt)
  print("u_anomaly_mjo min/max: " + min(u_filt) + "/" + max(u_filt))
  print("")
  printVarSummary(v_filt)
  print("v_anomaly_mjo min/max: " + min(v_filt) + "/" + max(v_filt))
  
end