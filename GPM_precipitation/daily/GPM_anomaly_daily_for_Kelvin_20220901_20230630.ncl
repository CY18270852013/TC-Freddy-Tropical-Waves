; 对GPM日降水异常数据进行滤波，提取Kelvin波信号
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/kf_filter.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/ut_string.ncl"

begin
  mis = -32767
  mis@_FillValue = -32767
  ymin    =  30 ; 北纬30度
  ymax    = -30 ; 南纬30度
  obsPerDay = 1
  varIn = "precipitation_anomaly"
  pathIn = "GPM_anomaly_daily_20220101_20231231_30S_30N.nc"
  pathOut = "GPM_anomaly_for_Kelvin_daily_20220901_20230630.nc"

  fin  = addfile( pathIn, "r" )
  lat_all = fin->lat
  lat_indices = ind(lat_all.ge.ymax .and. lat_all.le.ymin)
  lat = lat_all(lat_indices)
  lat@actual_range = (/ min(lat), max(lat) /)
  lon = fin->lon
  time_all = fin->time
  start_index = 243  ; 2022年9月1日（索引从0开始）
  end_index = 545    ; 2023年6月30日
  time_indices = ispan(start_index, end_index, 1)
  time = time_all(time_indices)

; 打开输出文件
  setfileoption( "nc", "Format", "LargeFile" )
  system( "rm -f " + pathOut ) ; 删除已存在的输出文件
  fout  = addfile( pathOut, "c" )
  fout->time = time
  fout->lat  = lat
  fout->lon  = lon

  data_full = fin->$varIn$
  ; 重新排列数据维度顺序为 [time, lat, lon]
  data_reordered = data_full(time|:, lat|:, lon|:)
  data = data_reordered(time_indices, lat_indices, :)
  ; 设置坐标变量
  data!0 = "time"
  data!1 = "lat" 
  data!2 = "lon"
  data&time = time
  data&lat = lat
  data&lon = lon
  ; 复制属性
  copy_VarAtts(data_full, data)
  data&time@beginning_date = "20220901"
  data&time@ending_date = "20230630"
  ; 释放内存
  delete(data_full)
  delete(data_reordered)
  print("处理后的数据摘要:")
  printVarSummary(data)

  ; Kelvin波滤波处理
  kelvin = data
  kelvin@long_name  = "Kelvin Waves in " + str_upper(varIn)
  kelvin@filter     = "Straub & Kiladis (2002)"
  kelvin@wavenumber = (/   1,  14 /)    ; 波数范围：1到14
  kelvin@period     = (/ 2.5,  17 /)    ; 周期范围：2.5到17天
  kelvin@depth      = (/   8,  90 /)    ; 深度参数
  do y = 0, ( dimsizes(lat) - 1 )
    kelvin(time|:,{lat|lat(y)},lon|:) = (/ kf_filter(  \
       data(time|:,{lat|lat(y)},lon|:), obsPerDay,  \
       kelvin@period(0),     kelvin@period(1),     \
       kelvin@wavenumber(0), kelvin@wavenumber(1), \
       kelvin@depth(0),      kelvin@depth(1),      \
       "kelvin" ) /)
  end do
  print("正在写入Kelvin波滤波结果..." )
  fout->kelvin = kelvin
  delete(kelvin)
  delete(fout)
  print("Kelvin波信号提取完成！输出文件: " + pathOut)
end 