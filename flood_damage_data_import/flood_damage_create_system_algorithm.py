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
    URL = 'https://storage.googleapis.com/skadesokonomi-dk-data/createscripts.json'

    def initAlgorithm(self, config):
        """
        Here we define the inputs and output of the algorithm, along
        with some other properties.
        """
  
        self.addParameter(QgsProcessingParameterString('server_name', 'IP name/adress for Database server', defaultValue='localhost'))
        self.addParameter(QgsProcessingParameterNumber('server_port','Port number for database server',type=QgsProcessingParameterNumber.Integer,minValue=1024, maxValue=49151, defaultValue=5432))
        self.addParameter(QgsProcessingParameterString('database_name', 'Name of new flood_damage database', defaultValue='flood_damage'))
        self.addParameter(QgsProcessingParameterString('adm_user', 'Administrative username', defaultValue='postgres' ))
        self.addParameter(QgsProcessingParameterString('adm_password', 'Administrative password', defaultValue='ukulemy'))

        adm_database = QgsProcessingParameterString('adm_database_name', 'Name of postgres system database', defaultValue='postgres')
        adm_database.setFlags(adm_database.flags() | QgsProcessingParameterDefinition.FlagAdvanced)
        self.addParameter(adm_database)

        fdc_admin = QgsProcessingParameterString('fdc_admin_schema', 'Name of flood_damage administration schema', defaultValue='fdc_admin')
        fdc_admin.setFlags(adm_database.flags() | QgsProcessingParameterDefinition.FlagAdvanced)
        self.addParameter(fdc_admin)

        fdc_lookup = QgsProcessingParameterString('fdc_lookup_schema', 'Name of flood_damage lookup schema', defaultValue='fdc_lookup')
        fdc_lookup.setFlags(adm_database.flags() | QgsProcessingParameterDefinition.FlagAdvanced)
        self.addParameter(fdc_lookup)

        fdc_sector = QgsProcessingParameterString('fdc_sector_schema', 'Name of flood_damage sectordata schema', defaultValue='fdc_sector')
        fdc_sector.setFlags(adm_database.flags() | QgsProcessingParameterDefinition.FlagAdvanced)
        self.addParameter(fdc_sector)

        fdc_flood = QgsProcessingParameterString('fdc_flood_schema', 'Name of flood_damage flood-data schema', defaultValue='fdc_flood')
        fdc_flood.setFlags(adm_database.flags() | QgsProcessingParameterDefinition.FlagAdvanced)
        self.addParameter(fdc_flood)

        fdc_result = QgsProcessingParameterString('fdc_result_schema', 'Name of flood_damage results schema', defaultValue='fdc_result')
        fdc_result.setFlags(adm_database.flags() | QgsProcessingParameterDefinition.FlagAdvanced)
        self.addParameter(fdc_result)

        fdc_connection = QgsProcessingParameterString('fdc_connection', 'Name of flood_damage database connection', defaultValue='{database_name} at {server_name} as {administrative_user}')
        fdc_connection.setFlags(adm_database.flags() | QgsProcessingParameterDefinition.FlagAdvanced)
        self.addParameter(fdc_connection)

    def processAlgorithm(self, parameters, context, feedback):
        """
        Here is where the processing itself takes place.
        """

        server_name = self.parameterAsString(parameters, 'server_name', context).replace ('"','')
        server_port = self.parameterAsString(parameters, 'server_port', context)
        database_name = self.parameterAsString(parameters, 'database_name', context).replace ('"','')
        adm_user = self.parameterAsString(parameters, 'adm_user', context)
        adm_password = self.parameterAsString(parameters, 'adm_password', context)
        
        adm_database = self.parameterAsString(parameters, 'adm_database', context).replace ('"','')      
        fdc_admin = self.parameterAsString(parameters, 'fdc_admin', context).replace ('"','')       
        fdc_lookup = self.parameterAsString(parameters, 'fdc_lookup', context).replace ('"','')       
        fdc_sector = self.parameterAsString(parameters, 'fdc_sector', context).replace ('"','')
        fdc_flood = self.parameterAsString(parameters, 'fdc_flood', context).replace ('"','')
        fdc_result = self.parameterAsString(parameters, 'fdc_result', context).replace ('"','')
        fdc_connection = self.parameterAsString(parameters, 'fdc_connection', context)

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

        uri.setConnection(server_name, server_port, database_name, adm_user, adm_password)
        conn_fdc = metadata.createConnection(uri.uri(), config)
   
        fdc_connection = fdc_connection.format(database_name=database_name,server_name=server_name,administrative_user=adm_user)
        conn_fdc.store(fdc_connection)
        
#       Hent script (extension, schemas, roles, application of roles)
        data = urlopen(self.URL).read().decode('utf-8')
        self.options = loads(data)

        
        

#        Replace tokens i script
#        Kør script
#        Hent data oversigt json
#        For hver section i json 
#        Hent  parametre sql script
#        Kør script
        

#        # Setup for progress indicator
#        total = 100.0 / len(selected_items) if len(selected_items) else 0
#        current = 1
#        
#        extr_result = {}
#
#        # Get connection
#
#        # Loop through selected layers        
#        for item in selected_items:
#
#            # Stop the algorithm if cancel button has been clicked
#            if feedback.isCanceled():
#                break
#            
#            feedback.pushInfo('\n\nProcessing layer {}....\n'.format(item))
#
#            # Find schema and table name in parameter table
#            #feedback.pushInfo('Export: SQL --> SELECT "value" FROM "{}"."{}" WHERE "name" = \'{}\''.format(schema_name, table_name, self.options[item]['dbkode']))
#            parm_table = connection.executeSql('SELECT "value" FROM "{}"."{}" WHERE "name" = \'{}\''.format(schema_name, table_name, self.options[item]['dbkode']))
#            full_name = parm_table[0][0] 
#
#            # Split full name into schema and table name
#            schtab = full_name.split('.',1)
#            exp_schema = schtab[0].replace('"','')
#            exp_table = schtab[1].replace('"','')
#
#            #feedback.pushInfo('Export: Full name = {}, Schemaname = {}, Tablename = {}'.format(full_name, exp_schema, exp_table))
#
#            # Find primary key column name in parameter table
#            #feedback.pushInfo('Geometry: SQL --> SELECT "value" FROM "{}"."{}" WHERE "name" like \'f_pkey_%\' AND parent = \'{}\''.format(schema_name, table_name, self.options[item]['dbkode']))
#            parm_table = connection.executeSql('SELECT "value" FROM "{}"."{}" WHERE "name" like \'f_pkey_%\' AND parent = \'{}\''.format(schema_name, table_name, self.options[item]['dbkode']))
#            exp_pkey = parm_table[0][0] 
#            
#            #feedback.pushInfo('Primary: Column name: {}'.format(exp_pkey))
#
#            # Find geometry column name in parameter table
#            #feedback.pushInfo('Geometry: SQL --> SELECT "value" FROM "{}"."{}" WHERE "name" like \'f_geom_%\' AND parent = \'{}\''.format(schema_name, table_name, self.options[item]['dbkode']))
#            parm_table = connection.executeSql('SELECT "value" FROM "{}"."{}" WHERE "name" like \'f_geom_%\' AND parent = \'{}\''.format(schema_name, table_name, self.options[item]['dbkode']))
#            exp_geom = parm_table[0][0] 
#            
#            #feedback.pushInfo('Geometry: Column name: {}'.format(exp_geom))
#
#
#            # Drop table if it exist beforehand
#            connection.executeSql('DROP TABLE IF EXISTS "{}"."{}"'.format(exp_schema, exp_table))
#
#            # Update uri with datasource
#            uri.setDataSource(exp_schema, exp_table, exp_geom, '', exp_pkey)
#            uri_upd = 'postgres://'+uri.uri()
#
#            #feedback.pushInfo('Updated URI: {}'.format(uri_upd))
#
#
#            # Activate processing algorithm with generated parameters
#            processing.run(
#                "native:extractbylocation", 
#                {
#                    'INPUT':     self.options[item]['adresse'],
#                    'PREDICATE': [0],
#                    'INTERSECT': parameters['layer_for_area_selection'],
#                    'OUTPUT':    uri_upd
#                },
#                is_child_algorithm=True, 
#                context=context, 
#                feedback=feedback
#            )
#            if open_layer:
#                context.addLayerToLoadOnCompletion(
#                    uri_upd,
#                    QgsProcessingContext.LayerDetails(
#                        item,
#                        context.project(),
#                        'LAYER'
#                    )
#                )
#
#            # Update the progress bar
#            feedback.setProgress(int(current* total))
#            current += 1 

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


    def get_postgres_conn_info(self, selected):
        """ Read PostgreSQL connection details from QSettings stored by QGIS
        """
        settings = QSettings()
        settings.beginGroup(u"/PostgreSQL/connections/" + selected)
    
        # password and username
        username = ''
        password = ''
        authconf = settings.value('authcfg', '')
        if authconf :
            # password encrypted in AuthManager
            auth_manager = QgsApplication.authManager()
            conf = QgsAuthMethodConfig()
            auth_manager.loadAuthenticationConfig(authconf, conf, True)
            if conf.id():
                username = conf.config('username', '')
                password = conf.config('password', '')
        else:
            # basic (plain-text) settings
            username = settings.value('username', '', type=str)
            password = settings.value('password', '', type=str)
        return username, password

