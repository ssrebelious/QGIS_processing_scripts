'''
===copyright===
Yury Ryabov
riabovvv@gmail.com
http://ssrebelious.blogspot.com
2015

The code here is provided under GPLv3 licence (http://www.gnu.org/licenses/gpl-3.0.html)
exept for the parts that are distributed under different term and conditions.
===copyright===

As usual this software provided 'AS IS' and there is no warranty
that it will work on your system, or that it will not cause any kind of damage.
Use it at your own risk.
'''

##Raster processing=group
##WV2_raster=raster
##IMD_file=file
##create_radiance_raster=boolean False
##radiance_raster=output raster
##create_reflectance_raster=boolean True
##reflectance_raster_multiplier=number 1
##reflectance_raster=output raster

from PyQt4 import QtGui
import re
import gdal
import math
import sys


path_list = [WV2_raster, IMD_file, radiance_raster, reflectance_raster]

rad = create_radiance_raster
ref = create_reflectance_raster
conditions = [rad, ref]

multiplier = reflectance_raster_multiplier

class EarthSunFail(QtGui.QMessageBox):
  '''
  Creates a message for the case when something is wrong with the Earth-Sun distance
  '''
  def __init__(self):
    super(EarthSunFail, self).__init__()

    self.initUI()

  def initUI(self):
    message = 'Earth-Sun distance has invalid value!'
    self.warning(self, 'Oops!',
        message, QtGui.QMessageBox.Ok)

def radioCorrectWV2(path_list, conditions = [False, True], multiplier = 1):
  '''
  Calculates WV2 imagery calibrated to the top-of-artmosfere radiance and reflectance

  path_list - list
      list of path to rasters [path_to_initial_raster, path_to_IMD_file, path_to_radiance, path_to_reflectance]
  conditions - list
      list of condiotions [radiance = False, reflectance = True]
  multiplier - numeric
      a multiplier for the reflectance raster to expand range of pixel values from
  '''
  #===copyright===
  #Yury Ryabov
  #riabovvv@gmail.com
  #http://ssrebelious.blogspot.com
  #2015

  #The code here is provided as is under GPLv3 licence (http://www.gnu.org/licenses/gpl-3.0.html)
  #exept for the parts that are distributed under different term and conditions.
  #===copyright===

  f = open(path_list[1], 'r')

  band_data = {} # {band:(absCalFactor, effectiveBandwidth)}

  band = 0
  abs_cal_factor = None
  bandwidth = None
  for line in f:
    band_pattern = re.findall(r'BEGIN_GROUP = BAND_(.+)', line) # look for the name of the band
    abs_cal_factor_pattern = re.findall(r'absCalFactor = (.+);', line) # look for absolute radiometric calibration factor
    bandwidth_pattern = re.findall(r'effectiveBandwidth = (.+);', line) # look for effective bandwidth
    sun_el_pattern = re.findall(r'meanSunEl = (.+);', line) # look for the mean Sun elevation
    acq_time_pattern = re.findall(r'earliestAcqTime = (.+);', line) # look for the acquire time


    if len(band_pattern) > 0:
      band += 1

    elif len(abs_cal_factor_pattern) > 0:
      abs_cal_factor = float(abs_cal_factor_pattern[0]) # absolute calibration factor

    elif len(bandwidth_pattern) > 0:
      bandwidth = float(bandwidth_pattern[0]) # effective bandwidth

    elif len(sun_el_pattern) > 0:
      sun_el = float(sun_el_pattern[0]) # Sun elevation
      theta = 90.0 - sun_el # solar zenith angle

    elif len(acq_time_pattern) > 0: # calculate the Julian Day and Earth-Sun distance (from "Radiometric Use of WorldView-2 Imagery.pdf")
      acq_time = acq_time_pattern[0] # YYYY_MM_DDThh:mm:ss:ddddddZ
      year = float(acq_time[:4])
      month = float(acq_time[5:7])
      if month <= 2:
        year -= 1
        month += 12
      day = float(acq_time[8:10])
      hour = float(acq_time[11:13])
      minuetes = float(acq_time[14:16])
      seconds = float(acq_time[17:19] + '.' + acq_time[20:26])
      UT = hour + minuetes/60.0 + seconds/3600.0
      A = int(year/100)
      B = 2 - A + int(A/4)
      JD = int(365.25*(year + 4716)) + int(30.6001*(month + 1)) + day + UT + B - 1524.5 # Julian Day
      D = JD - 2451545.0
      g = 357.529 + 0.98560028 * D # in degrees
      g = math.radians(g) # in radians, because math.cos require radians
      des = 1.00014 - 0.01671 * math.cos(g) - 0.00014 * math.cos(2*g) # Earth-Sun distance
      if des < 0.983 or des > 1.017:
        print 'Earth-Sun distance has invalid value!' %(des)
        EarthSunFail(des)
        return False

    # write some of gathered data to dict
    if abs_cal_factor != None and bandwidth != None:
      band_data[band] = (abs_cal_factor, bandwidth)
      abs_cal_factor = None
      bandwidth_pattern = None

  #print band_data
  f.close()

  raster = gdal.Open(path_list[0])

  # Get raster data:
  xsize = raster.RasterXSize
  ysize = raster.RasterYSize
  proj = raster.GetProjection()
  geo_transform = raster.GetGeoTransform()
  n_bands = raster.RasterCount

  # Band-Averaged Solar Spectral Irradiance
  Pan = 1580.8140
  Coastal = 1758.2229
  Blue = 1974.2416
  Green = 1856.4104
  Yellow = 1738.4791
  Red = 1559.4555
  Red_Edge = 1342.0695
  NIR1 = 1069.7302
  NIR2 = 861.2866
  solar_irr = {} # {band:solar_irradiance}
  if n_bands == 1:
    solar_irr[1] = Pan
  else:
    irr_list = [Coastal, Blue, Green, Yellow, Red, Red_Edge, NIR1, NIR2]
    l = len(irr_list)
    for i in xrange(1, l+1):
      solar_irr[i] = irr_list[i-1]


  r_format = "GTiff"
  driver = gdal.GetDriverByName( r_format )
  metadata = driver.GetMetadata()
  if metadata.has_key( gdal.DCAP_CREATE ) and metadata[ gdal.DCAP_CREATE ] == "YES":
    pass
  else:
    print "Driver %s does not support Create() method." % r_format
    #sys.exit( 1 )

  if conditions[0]: # we need to calculate top-of-atmosphere spectral radiance
    radiance_raster = driver.CreateCopy( path_list[2], raster, 0 )
  if conditions[1]: # we need to calculate top-of-atmosphere reflectanse
    reflectance_raster =  driver.Create( path_list[3], xsize, ysize, n_bands, gdal.GDT_Float32 ) #driver.CreateCopy( path_list[3], raster, 1 )

  for i in xrange(1, (n_bands + 1)):
    band = raster.GetRasterBand(i)
    band = band.ReadAsArray()
    band = (band * band_data[i][0]) / band_data[i][1]
    if conditions[1]:
      band_1 = ( band * (des ** 2) * math.pi) / ( solar_irr[i]  * math.cos(theta) )
      if multiplier != 1:
        band_1 *= multiplier
      reflectance_raster.GetRasterBand(i).WriteArray(band_1) # write result to output file
    if conditions[0]:
      radiance_raster.GetRasterBand(i).WriteArray(band) # write result to output file

  if conditions[1]: # set geo data to reflectance raster
    reflectance_raster.SetProjection(proj)
    reflectance_raster.SetGeoTransform(geo_transform)
  raster = None
  radiance_raster = None
  reflectance_raster = None

  return True

radioCorrectWV2(path_list, conditions, multiplier)