; 对GPM日降水异常数据进行滤波，提取MJO信号
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/kf_filter.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/ut_string.ncl"

begin
  ; 设置参数
  mis = -32767
  mis@_FillValue = -32767
  ymin    =  30 ; 北纬30度
  ymax    = -30 ; 南纬30度
  obsPerDay = 1
  varIn = "precipitation_anomaly"
  pathIn = "GPM_anomaly_daily_20220101_20231231_30S_30N.nc"
  pathOut = "GPM_anomaly_for_MJO_daily_20220901_20230630.nc"

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
  ; 写入维度变量
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
  ; 设置时间属性
  data&time@beginning_date = "20220901"
  data&time@ending_date = "20230630"
  ; 释放内存
  delete(data_full)
  delete(data_reordered)

  ; MJO滤波
  print("正在进行MJO滤波..." )
  mjo = data
  mjo@long_name     = "Madden-Julian Oscillation in " + str_upper(varIn)
  mjo@filter        = "Kiladis et al. (2005 JAS)"
  mjo@wavenumber    = (/   1,   9 /)    ; 波数范围：1到9
  mjo@period        = (/  30, 96 /)    ; 周期范围：30到96天
  mjo@depth         = (/ mis, mis /)    ; 深度参数不使用
  ; 对每个纬度进行滤波
  do y = 0, ( dimsizes(lat) - 1 )
    mjo(time|:,{lat|lat(y)},lon|:) = (/ kf_filter(  \
       data(time|:,{lat|lat(y)},lon|:), obsPerDay,  \
       mjo@period(0),     mjo@period(1),     \
       mjo@wavenumber(0), mjo@wavenumber(1), \
       mjo@depth(0),      mjo@depth(1),      \
       "none" ) /)
  end do
  print("正在写入MJO滤波结果..." )
  fout->mjo = mjo

  delete(mjo)
  delete(fout)
  print("MJO信号提取完成！输出文件: " + pathOut)
end 