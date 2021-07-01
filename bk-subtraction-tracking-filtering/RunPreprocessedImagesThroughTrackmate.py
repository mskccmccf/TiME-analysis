from fiji.plugin.trackmate import Model
from fiji.plugin.trackmate import Settings
from fiji.plugin.trackmate import TrackMate
from fiji.plugin.trackmate import SelectionModel
from fiji.plugin.trackmate import Logger
from fiji.plugin.trackmate.detection import DogDetectorFactory
from fiji.plugin.trackmate.tracking.sparselap import SparseLAPTrackerFactory
from fiji.plugin.trackmate.tracking import LAPUtils
from fiji.plugin.trackmate.action import ExportTracksToXML
from os import listdir
from ij import IJ
import java.io.File as File
import fiji.plugin.trackmate.visualization.hyperstack.HyperStackDisplayer as HyperStackDisplayer
import fiji.plugin.trackmate.features.FeatureFilter as FeatureFilter
import sys
import fiji.plugin.trackmate.features.track.TrackDurationAnalyzer as TrackDurationAnalyzer
import fiji.plugin.trackmate.features.track.TrackSpeedStatisticsAnalyzer as TrackSpeedStatisticsAnalyzer
import fiji.plugin.trackmate.features.track.TrackSpotQualityFeatureAnalyzer as TrackSpotQualityFeatureAnalyzer
import fiji.plugin.trackmate.features.edges.EdgeVelocityAnalyzer as EdgeVelocityAnalyzer
import fiji.plugin.trackmate.features.edges.EdgeTargetAnalyzer as EdgeTargetAnalyzer

import fiji.plugin.trackmate.io.TmXmlWriter as TmXmlWriter
   
# Get currently selected image
#imp = WindowManager.getCurrentImage()
#imp = IJ.openImage('C:\Users\MCCFAdmin\Desktop\testfullyaligned5\Lk_movie2_cropstabilizedimage_bksubmin.tif')



##@File(label = "Input file", style = "file") file
#outputFolder= "C:\\Users\\MCCFAdmin\\Desktop\\localoutput_scatteringtest\\"
#outputFolder= "C:\\Users\\MCCFAdmin\\Desktop\\localoutput_scattering\\pcp\\"
#outputFolder= "D:\\core\\aditistuff\\correctwindowed30_15_withnorm\\bkdiv\\"
outputFolder= "D:\\core\\aditistuff\\FullDataSetNew\\SIFT Output VERSION 2_Aditi edited\\cropped_aligned\sub\\"
#outputFolder= "D:\\core\\aditistuff\\correctwindowed30_15_withnorm_median\\sub\\"
filelist=listdir(outputFolder)

for file in filelist:
	curfile=File(outputFolder,file)
	print "processing "+file
	imp = IJ.openImage(curfile.getAbsolutePath())
	#imp = IJ.openImage('http://fiji.sc/samples/FakeTracks.tif')
	#imp.show()
	#switch dims bc I have no metadata
	# no longer necessary bc used bioformats to save from matlab
	#dims = imp.getDimensions();
	#imp.setDimensions( dims[ 2 ], dims[ 4 ], dims[ 3 ] );
		
		  
	#----------------------------
	# Create the model object now
		#----------------------------
		   
		# Some of the parameters we configure below need to have
		# a reference to the model at creation. So we create an
		# empty model now.
	model = Model()
		   
		# Send all messages to ImageJ log window.
	model.setLogger(Logger.IJ_LOGGER)
		
		#------------------------
		# Prepare settings object
		#------------------------
		      
	settings = Settings()
	settings.setFrom(imp)
		      
		# Configure detector - We use the Strings for the keys
		#2.25 is alternate threshold considered for 
	settings.detectorFactory = DogDetectorFactory()
	settings.detectorSettings = { 
		    'DO_SUBPIXEL_LOCALIZATION' : True,
		    'RADIUS' : 7.5,
		    'TARGET_CHANNEL' : 1,
		    'THRESHOLD' : 1.6,
		    'DO_MEDIAN_FILTERING' : False,
	}  
	
	#old min based sub
		   #.15 was ok on div but was losing some and way overseg for others
		    #was 3.0 for subtraction 2.25 for other bksub
		# Configure tracker - We want to allow merges and fusions
	settings.trackerFactory = SparseLAPTrackerFactory()
	settings.trackerSettings = LAPUtils.getDefaultLAPSettingsMap() # almost good enough
	settings.trackerSettings['ALLOW_TRACK_SPLITTING'] = False
	settings.trackerSettings['ALLOW_TRACK_MERGING'] = False
	settings.trackerSettings['GAP_CLOSING_MAX_DISTANCE']= 0.0
	settings.trackerSettings['LINKING_MAX_DISTANCE']= 20.0
		  
		# Configure track analyzers - Later on we want to filter out tracks 
		# based on their displacement, so we need to state that we want 
		# track displacement to be calculated. By default, out of the GUI, 
		# not features are calculated. 
		   
		# The displacement feature is provided by the TrackDurationAnalyzer.
	settings.addTrackAnalyzer(TrackSpeedStatisticsAnalyzer())
	settings.addTrackAnalyzer(TrackDurationAnalyzer())
	settings.addTrackAnalyzer(TrackSpotQualityFeatureAnalyzer())
	settings.addEdgeAnalyzer(EdgeVelocityAnalyzer())	
	settings.addEdgeAnalyzer(EdgeTargetAnalyzer())	
		# Configure track filters - We want to get rid of the two immobile spots at 
		# the bottom right of the image. Track displacement must be above 10 pixels.
		
		## Commented for debug
	#filter2 = FeatureFilter('TRACK_DISPLACEMENT', 10, True)
	#lowest acceptable threshold for now rest done in post production
	filter2 = FeatureFilter('TRACK_DURATION', 2, True)
	
	settings.addTrackFilter(filter2)
		   
		#-------------------
		# Instantiate plugin
		#-------------------
		   
	trackmate = TrackMate(model, settings)
		      
		#--------
		# Process
		#--------
		   
	ok = trackmate.checkInput()
	if not ok:
		   sys.exit(str(trackmate.getErrorMessage()))
		   
	ok = trackmate.process()
	if not ok:
	    sys.exit(str(trackmate.getErrorMessage()))

	
	#outFile = File(outputFolder, curfile.getName()+"exportTracks.xml")
	#ExportTracksToXML.export(model, settings, outFile)
		
	outFile = File(outputFolder, curfile.getName()+"exportModel.xml")
	writer = TmXmlWriter(outFile)
	writer.appendModel(model)
	writer.appendSettings(settings)
	writer.writeToFile()
	print "All Done!"
	
		#----------------
		# Display results
		#----------------
		     
	#selectionModel = SelectionModel(model)
	#displayer =  HyperStackDisplayer(model, selectionModel, imp)
	#displayer.render()
	#displayer.refresh()
		
	# Echo results with the logger we set at start:
	model.getLogger().log(str(model))