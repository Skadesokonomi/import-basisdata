# -*- coding: utf-8 -*-

"""
/***************************************************************************
 FDDataImport
                                 A QGIS plugin
 QGIS processing plugin to import data from web based flatgeobuf data sources til flood damage database
 Generated by Plugin Builder: http://g-sherman.github.io/Qgis-Plugin-Builder/
                              -------------------
        begin                : 2023-10-24
        copyright            : (C) 2023 by Bo Victor Thomsen AestasGIS Denmark
        email                : bvt@aestas.dk
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
"""

__author__ = 'Bo Victor Thomsen AestasGIS Denmark'
__date__ = '2023-10-24'
__copyright__ = '(C) 2023 by Bo Victor Thomsen AestasGIS Denmark'

# This will get replaced with a git SHA1 when you do a git archive

__revision__ = '$Format:%H$'

from qgis.core import QgsProcessingProvider
from .flood_damage_data_import_algorithm   import FDCDataImportAlgorithm
from .flood_damage_create_system_algorithm import FDCCreateSystemAlgorithm
from .flood_damage_update_system_algorithm import FDCUpdateSystemAlgorithm
from .flood_damage_user_admin_algorithm    import FDCUserAdminAlgorithm
from .flood_damage_raster_polygon_classification_algorithm  import FDCRasterPolygonClassification
from .flood_damage_raster_polygon_pixels_algorithm          import FDCRasterPolygonPixels


class FloodDamageCostAdmin(QgsProcessingProvider):

    def __init__(self):
        """
        Default constructor.
        """
        QgsProcessingProvider.__init__(self)

    def unload(self):
        """
        Unloads the provider. Any tear-down steps required by the provider
        should be implemented here.
        """
        pass

    def loadAlgorithms(self):
        """
        Loads all algorithms belonging to this provider.
        """
        self.addAlgorithm(FDCDataImportAlgorithm())
        self.addAlgorithm(FDCCreateSystemAlgorithm())
        self.addAlgorithm(FDCUpdateSystemAlgorithm())
        self.addAlgorithm(FDCUserAdminAlgorithm())
        self.addAlgorithm(FDCRasterPolygonClassification())
        self.addAlgorithm(FDCRasterPolygonPixels())
        # add additional algorithms here
        # self.addAlgorithm(MyOtherAlgorithm())

    def id(self):
        """
        Returns the unique provider id, used for identifying the provider. This
        string should be a unique, short, character only string, eg "qgis" or
        "gdal". This string should not be localised.
        """
        return 'fdccost'

    def name(self):
        """
        Returns the provider name, which is used to describe the provider
        within the GUI.

        This string should be short (e.g. "Lastools") and localised.
        """
        return self.tr('FDC cost administration')

    def icon(self):
        """
        Should return a QIcon which is used for your provider inside
        the Processing toolbox.
        """
        return QgsProcessingProvider.icon(self)

    def longName(self):
        """
        Returns the a longer version of the provider name, which can include
        extra details such as version numbers. E.g. "Lastools LIDAR tools
        (version 2.2.1)". This string should be localised. The default
        implementation returns the same string as name().
        """
        return self.tr('OS2 Flood Damage Cost administration')