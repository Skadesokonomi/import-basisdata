# -*- coding: utf-8 -*-

"""
/***************************************************************************
 FDUpdateSystem
                                 A QGIS plugin
 QGIS processing plugin to initial setup of flood damage database including security 
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

__author__ = 'Bo Victor Thomsen, AestasGIS Denmark'
__date__ = '2023-10-24'
__copyright__ = '(C) 2023 by Bo Victor Thomsen, AestasGIS Denmark'

# This will get replaced with a git SHA1 when you do a git archive

__revision__ = '$Format:%H$'

from qgis.PyQt.QtCore import QCoreApplication, QSettings

from qgis.core import (QgsProcessing,
                       QgsFeatureSink,
                       QgsProcessingAlgorithm,
                       QgsProcessingParameterFeatureSource,
                       QgsProcessingParameterFeatureSink,
                       QgsProcessingParameterDatabaseSchema,
                       QgsProcessingParameterDatabaseTable,
                       QgsProcessingParameterProviderConnection,
                       QgsProcessingParameterEnum,
                       QgsProcessingParameterDefinition,
                       QgsProcessingParameterBoolean,
                       QgsProcessingParameterString,
                       QgsProcessingParameterNumber,
                       QgsProcessingMultiStepFeedback,
                       QgsProviderConnectionException,
                       QgsVectorLayer,
                       QgsProviderRegistry,
                       QgsDataSourceUri,
                       QgsAuthMethodConfig,
                       QgsApplication,
                       QgsSettings,
                       QgsProcessingContext)
                       
from qgis import processing
from json import loads, dumps
from urllib.request import urlopen
import datetime

class FDCUpdateSystemAlgorithm(QgsProcessingAlgorithm):
    """
    Blah blah blah
    """

    # Constants used to refer to parameters and outputs. They will be
    # used when calling the algorithm from another algorithm, or when
    # calling from the QGIS console.

    OUTPUT = 'OUTPUT'
    INPUT = 'INPUT'
    DEF_URL = 'https://storage.googleapis.com/skadesokonomi-dk-data/'

    def initAlgorithm(self, config):
        """
        Here we define the inputs and output of the algorithm, along
        with some other properties.
        """

        s = QgsSettings()  

        # Force advanced section to be folded         
        self.folded = s.value("QgsCollapsibleGroupBox/QgsProcessingDialogBase/grpAdvanced/collapsed", None) # save original state
        s.setValue("QgsCollapsibleGroupBox/QgsProcessingDialogBase/grpAdvanced/collapsed", True) # Force collapsed to True 

        # Find saved url
        url = s.value("flood_damage/url", None)

        # If url setting doesn't exist, create it using default value
        if not url: url = self.DEF_URL 
        url += '' if url[-1]=='/' else '/'
        s.setValue("flood_damage/url", url)
 
        data = urlopen(url + 'updatescripts.json').read().decode('utf-8')
        self.options = loads(data)
        self.option_list =[key for key in self.options]
 
        self.addParameter(QgsProcessingParameterEnum('run_scripts', 'Choose which SQL scripts to run', ['{} ... {}'.format(key,self.options[key]['dato']) for key in self.options], allowMultiple=True, defaultValue=[]))
        param = QgsProcessingParameterProviderConnection('database_connection', 'Database connection', 'postgres', defaultValue='flood damage')
        #param.setFlags(param.flags() | QgsProcessingParameterDefinition.FlagAdvanced)
        self.addParameter(param)
        self.addParameter(QgsProcessingParameterBoolean('overwrite_updates', 'Overwrite existing updates', defaultValue=False))



    def processAlgorithm(self, parameters, context, feedback):
        """
        Here is where the processing itself takes place.
        """
        
        TEMPLATE = """
        INSERT INTO "{schema}"."{table}" (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable)
            VALUES ('{name}','{parent}','{value}','T', '', '', '', '', '** Autoupdated**', 10, ' ')
            ON CONFLICT (name) DO UPDATE SET value = '{value}', parent = '{parent}'
        """          

        TEMPLATE2 = """
        INSERT INTO fdc_admin.patches_done (patch_name, long_name, created, run_at) 
            VALUES ('{patch_name}','{long_name}','{created}','{run_at}')
            ON CONFLICT (patch_name) DO UPDATE SET run_at = '{run_at}'
        """          


        feedback = QgsProcessingMultiStepFeedback(1, feedback)
        s = QgsSettings() 
        s.setValue("QgsCollapsibleGroupBox/QgsProcessingDialogBase/grpAdvanced/collapsed", self.folded) # Restore original state

        user_options = self.parameterAsEnums(parameters, 'import_layers', context)
        selected_items = [self.option_list[i] for i in user_options]

        # Get connection
        connection_name = self.parameterAsString(parameters, 'database_connection', context)
        metadata = QgsProviderRegistry.instance().providerMetadata('postgres')
        conn_fdc = metadata.findConnection(connection_name)

        user_options = self.parameterAsEnums(parameters, 'run_scripts', context)
        selected_items = [self.option_list[i] for i in user_options]

        overwrite_updates = self.parameterAsBoolean(parameters, 'overwrite_updates', context)

        # Setup for progress indicator
        total = 100.0 / len(selected_items) if len(selected_items) else 0
        current = 1

        current_time = datetime.datetime.now()
            
        # Loop through selected scripts        
        for item in selected_items:

            # Stop the algorithm if cancel button has been clicked
            if feedback.isCanceled():
                break
            
            feedback.pushInfo('\n\nProcessing script: {}....\n'.format(item))

            # Check that all prerequisites are in place.
            diff = 0
            prerequisit = self.options[item]['forudsætning']
            if prerequisit:
                cnt_lst = len(prerequisit)
                pr_list = conn_fdc.executeSql('SELECT COUNT(*) FROM fdc_admin.patches_done WHERE patch_name IN = (\'{}\')'.format('\',\''.join(prerequisit)))
                diff = cnt_len-pr_list[0][0] 

            if diff == 0: 

                update_exists = conn_fdc.executeSql('SELECT COUNT(*) FROM fdc_admin.patches_done WHERE patch_name =\'{}\''.format(self.options[item]['navn']))
                if update_exists[0][0]==0 or overwrite_updates: 

               
                    data = urlopen(self.options[item]['adresse']).read().decode('utf-8')
                    #data = data.replace('{database_name}',database_name).replace('{fdc_admin_role}',fdc_admin_role).replace('{fdc_model_role}',fdc_model_role).replace('{fdc_read_role}',fdc_read_role)
                    conn_fdc.executeSql(data)
         
                    # Update fields information in parameter list
                    if 'dbkeys' in self.options[item]:
                        for k,v in self.options[item]['dbkeys'].items():
                            sqlstr = TEMPLATE.format(schema='fdc_admin', table='parametre', name=k, value=v[0], parent=v[1])
                            feedback.pushInfo('setting field sql: {}'.format(sqlstr))
                            parm_table = conn_fdc.executeSql(sqlstr)

                    conn_fdc.executeSql(
                        TEMPLATE2.format(
                        patch_name=self.options[item]['navn'],long_name=self.options[item]['forklaring'],created=self.options[item]['dato'],run_at=current_time))

                else:
                    feedback.reportError('Update: {} - {} - previously done'.format(self.options[item]['navn'],self.options[item]['forklaring']))
                
            else: 
                feedback.reportError('Prerequisites for update are missing')
            
            # Update the progress bar
            feedback.setProgress(int(current* total))
            current += 1 

        return {'connection name': connection_name}


    def name(self):
        """
        Returns the algorithm name, used for identifying the algorithm. This
        string should be fixed for the algorithm, and must not be localised.
        The name should be unique within each provider. Names should contain
        lowercase alphanumeric characters only and no spaces or other
        formatting characters.
        """
        return 'flood_damage_update_system'

    def displayName(self):
        """
        Returns the translated algorithm name, which should be used for any
        user-visible display of the algorithm name.
        """
        return self.tr('OS2 Flood Damage Cost update system')

    def group(self):
        """
        Returns the name of the group this algorithm belongs to. This string
        should be localised.
        """
        return self.tr('')

    def groupId(self):
        """
        Returns the unique ID of the group this algorithm belongs to. This
        string should be fixed for the algorithm, and must not be localised.
        The group id should be unique within each provider. Group id should
        contain lowercase alphanumeric characters only and no spaces or other
        formatting characters.
        """
        return ''

    def tr(self, string):
        return QCoreApplication.translate('Processing', string)

    def createInstance(self):
        return FDCUpdateSystemAlgorithm()

