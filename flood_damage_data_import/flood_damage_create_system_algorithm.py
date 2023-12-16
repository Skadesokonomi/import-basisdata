# -*- coding: utf-8 -*-

"""
/***************************************************************************
 FDCreateSystem
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

class FDCreateSystemAlgorithm(QgsProcessingAlgorithm):
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
 
        data = urlopen(url + 'createscripts.json').read().decode('utf-8')
        self.options = loads(data)
        self.option_list =[key for key in self.options]
 
        self.addParameter(QgsProcessingParameterString('server_name', 'IP name/adress for Database server', defaultValue='localhost'))
        self.addParameter(QgsProcessingParameterNumber('server_port','Port number for database server',type=QgsProcessingParameterNumber.Integer,minValue=1024, maxValue=49151, defaultValue=5432))
        self.addParameter(QgsProcessingParameterString('adm_user', 'Administrative username', defaultValue='postgres' ))
        self.addParameter(QgsProcessingParameterString('adm_password', 'Administrative password', defaultValue='ukulemy'))
        self.addParameter(QgsProcessingParameterString('database_name', 'Name of new flood_damage database', defaultValue='flood_damage'))
        self.addParameter(QgsProcessingParameterEnum('run_scripts', 'Choose which SQL scripts to run', ['{} ... {}'.format(key,self.options[key]['dato']) for key in self.options], allowMultiple=True, defaultValue=[0,1,2,3]))

        fdc_connection = QgsProcessingParameterString('fdc_connection', 'Name of flood_damage database connection', defaultValue='{database_name} at {server_name} as {administrative_user}')
        #fdc_connection.setFlags(adm_database.flags() | QgsProcessingParameterDefinition.FlagAdvanced)
        self.addParameter(fdc_connection)

        fdc_admin_role = QgsProcessingParameterString('fdc_admin_role', 'Name of administrator role for new database', defaultValue='{database_name}_admin_role')
        #fdc_admin_role.setFlags(fdc_admin_role.flags() | QgsProcessingParameterDefinition.FlagAdvanced)
        self.addParameter(fdc_admin_role)

        fdc_model_role = QgsProcessingParameterString('fdc_model_role', 'Name of modeler role for new database', defaultValue='{database_name}_model_role')
        #fdc_model_role.setFlags(fdc_model_role.flags() | QgsProcessingParameterDefinition.FlagAdvanced)
        self.addParameter(fdc_model_role)

        fdc_read_role = QgsProcessingParameterString('fdc_read_role', 'Name of reader role for new database', defaultValue='{database_name}_read_role')
        #fdc_read_role.setFlags(fdc_read_role.flags() | QgsProcessingParameterDefinition.FlagAdvanced)
        self.addParameter(fdc_read_role)

        param = QgsProcessingParameterString('repository_url', 'Repository URL (Reference only)', defaultValue=url + 'createscripts.json')
        param.setFlags(param.flags() | QgsProcessingParameterDefinition.FlagAdvanced)
        self.addParameter(param)

        adm_database = QgsProcessingParameterString('adm_database_name', 'Name of postgres system database', defaultValue='postgres')
        adm_database.setFlags(adm_database.flags() | QgsProcessingParameterDefinition.FlagAdvanced)
        self.addParameter(adm_database)
        
#        fdc_admin_pwd = QgsProcessingParameterString('fdc_admin_pwd', 'Password for administrator role (empty -> Non-interactive group role)', defaultValue='', optional=True)
#        fdc_admin_pwd.setFlags(fdc_admin_pwd.flags() | QgsProcessingParameterDefinition.FlagAdvanced)
#        self.addParameter(fdc_admin_pwd)
#
#
#        fdc_model_pwd = QgsProcessingParameterString('fdc_model_pwd', 'Password for modeler role (empty -> Non-interactive group role)', defaultValue='', optional=True)
#        fdc_model_pwd.setFlags(fdc_model_pwd.flags() | QgsProcessingParameterDefinition.FlagAdvanced)
#        self.addParameter(fdc_model_pwd)
#
#
#        fdc_read_pwd = QgsProcessingParameterString('fdc_read_pwd', 'Password for reader role (empty -> Non-interactive group role)', defaultValue='', optional=True)
#        fdc_read_pwd.setFlags(fdc_read_pwd.flags() | QgsProcessingParameterDefinition.FlagAdvanced)
#        self.addParameter(fdc_read_pwd)


    def processAlgorithm(self, parameters, context, feedback):
        """
        Here is where the processing itself takes place.
        """
        
        TEMPLATE = """
        INSERT INTO "{schema}"."{table}" (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable)
            VALUES ('{name}','{parent}','{value}','T', '', '', '', '', '** Autoupdated**', 10, ' ')
            ON CONFLICT (name) DO UPDATE SET value = '{value}', parent = '{parent}'
        """          


        s = QgsSettings() 
        s.setValue("QgsCollapsibleGroupBox/QgsProcessingDialogBase/grpAdvanced/collapsed", self.folded) # Restore original state

        user_options = self.parameterAsEnums(parameters, 'run_scripts', context)
        selected_items = [self.option_list[i] for i in user_options]


        server_name = self.parameterAsString(parameters, 'server_name', context).replace ('"','')
        server_port = self.parameterAsString(parameters, 'server_port', context)
        database_name = self.parameterAsString(parameters, 'database_name', context).replace ('"','')
        adm_user = self.parameterAsString(parameters, 'adm_user', context)
        adm_password = self.parameterAsString(parameters, 'adm_password', context)
        adm_database = self.parameterAsString(parameters, 'adm_database', context)
        fdc_connection = self.parameterAsString(parameters, 'fdc_connection', context)
        fdc_admin_role = self.parameterAsString(parameters, 'fdc_admin_role', context)
#        fdc_admin_pwd = self.parameterAsString(parameters, 'fdc_admin_pwd', context)
        fdc_model_role = self.parameterAsString(parameters, 'fdc_model_role', context)
#        fdc_model_pwd = self.parameterAsString(parameters, 'fdc_model_pwd', context)
        fdc_read_role = self.parameterAsString(parameters, 'fdc_read_role', context)
#        fdc_read_pwd = self.parameterAsString(parameters, 'fdc_read_pwd', context)

        # Replace token with actual values
        fdc_connection = fdc_connection.format(database_name=database_name,server_name=server_name,administrative_user=adm_user)
        fdc_admin_role = fdc_admin_role.format(database_name=database_name,server_name=server_name,administrative_user=adm_user)
        fdc_model_role = fdc_model_role.format(database_name=database_name,server_name=server_name,administrative_user=adm_user)
        fdc_read_role = fdc_read_role.format(database_name=database_name,server_name=server_name,administrative_user=adm_user)

        # Create connection administrative postgres database (postgres)
        uri = QgsDataSourceUri()
        uri.setConnection(server_name, server_port, adm_database, adm_user, adm_password)

        config = {
          "saveUsername": True,
          "savePassword": True,
          "estimatedMetadata": True,
          "metadataInDatabase": True,
        }

        metadata = QgsProviderRegistry.instance().providerMetadata('postgres')
        conn_adm = metadata.createConnection(uri.uri(), config)
            
        # Create fdc database
        sql = 'CREATE DATABASE "{}"'.format(database_name)
        conn_adm.executeSql(sql)
<<<<<<< HEAD

=======
        
>>>>>>> 3f8966ac909005b75a8b35401e8afa4ef0451dde
        uri.setConnection(server_name, server_port, database_name, adm_user, adm_password)
        conn_fdc = metadata.createConnection(uri.uri(), config)
   
        conn_fdc.store(fdc_connection)


        # Setup for progress indicator
        total = 100.0 / len(selected_items) if len(selected_items) else 0
        current = 1
        
        extr_result = {}

        # Loop through selected scripts        
        for item in selected_items:

            # Stop the algorithm if cancel button has been clicked
            if feedback.isCanceled():
                break
            
            feedback.pushInfo('\n\nProcessing script: {}....\n'.format(item))

            data = urlopen(self.options[item]['adresse']).read().decode('utf-8')
            data = data.replace('{database_name}',database_name).replace('{fdc_admin_role}',fdc_admin_role).replace('{fdc_model_role}',fdc_model_role).replace('{fdc_read_role}',fdc_read_role)
            conn_fdc.executeSql(data)

            # Update fields information in parameter list
            if 'dbkeys' in self.options[item]:
                for k,v in self.options[item]['dbkeys'].items():
                    sqlstr = TEMPLATE.format(schema='fdc_admin', table='parametre', name=k, value=v[0], parent=v[1])
                    feedback.pushInfo('setting field sql: {}'.format(sqlstr))
                    parm_table = conn_fdc.executeSql(sqlstr)

            # Update the progress bar
            feedback.setProgress(int(current* total))
            current += 1 

<<<<<<< HEAD
        if fdc_admin_pwd and fdc_admin_pwd.replace (' ','') != '': 
            sql = 'ALTER ROLE "{}" LOGIN PASSWORD \'{}\''.format(fdc_admin_role, fdc_admin_pwd)
            conn_adm.executeSql(sql)

        if fdc_model_pwd and fdc_model_pwd.replace (' ','') != '': 
            sql = 'ALTER ROLE "{}" LOGIN PASSWORD \'{}\''.format(fdc_model_role, fdc_model_pwd)
            conn_adm.executeSql(sql)

        if fdc_read_pwd and fdc_read_pwd.replace (' ','') != '': 
            sql = 'ALTER ROLE "{}" LOGIN PASSWORD \'{}\''.format(fdc_read_role, fdc_read_pwd)
            conn_adm.executeSql(sql)
=======
#        if fdc_admin_pwd and fdc_admin_pwd.replace (' ','') != '': 
#            sql = 'ALTER ROLE "{}" LOGIN PASSWORD \'{}\''.format(fdc_admin_role, fdc_admin_pwd)
#            conn_adm.executeSql(sql)
#
#        if fdc_model_pwd and fdc_model_pwd.replace (' ','') != '': 
#            sql = 'ALTER ROLE "{}" LOGIN PASSWORD \'{}\''.format(fdc_model_role, fdc_model_pwd)
#            conn_adm.executeSql(sql)
#
#        if fdc_read_pwd and fdc_read_pwd.replace (' ','') != '': 
#            sql = 'ALTER ROLE "{}" LOGIN PASSWORD \'{}\''.format(fdc_read_role, fdc_read_pwd)
#            conn_adm.executeSql(sql)

        sqlstr = TEMPLATE.format(schema='fdc_admin', table='parametre', name='Name, admin role', value=fdc_admin_role, parent='SQL templates')
        parm_table = conn_fdc.executeSql(sqlstr)

        sqlstr = TEMPLATE.format(schema='fdc_admin', table='parametre', name='Name, model role', value=fdc_model_role, parent='SQL templates')
        parm_table = conn_fdc.executeSql(sqlstr)

        sqlstr = TEMPLATE.format(schema='fdc_admin', table='parametre', name='Name, reader role', value=fdc_read_role, parent='SQL templates')
        parm_table = conn_fdc.executeSql(sqlstr)
>>>>>>> 3f8966ac909005b75a8b35401e8afa4ef0451dde

        return {'connection name': fdc_connection}


    def name(self):
        """
        Returns the algorithm name, used for identifying the algorithm. This
        string should be fixed for the algorithm, and must not be localised.
        The name should be unique within each provider. Names should contain
        lowercase alphanumeric characters only and no spaces or other
        formatting characters.
        """
        return 'flood_damage_create_system'

    def displayName(self):
        """
        Returns the translated algorithm name, which should be used for any
        user-visible display of the algorithm name.
        """
        return self.tr('Flood Damage create system')

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
        return FDCreateSystemAlgorithm()

