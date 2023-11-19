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
                       QgsVectorLayer,
                       QgsProviderRegistry,
                       QgsDataSourceUri,
                       QgsAuthMethodConfig,
                       QgsApplication,
                       QgsProcessingContext)
                       
from qgis import processing
                      

class FDDataImportAlgorithm(QgsProcessingAlgorithm):
    """
    Blah blah blah
    """

    # Constants used to refer to parameters and outputs. They will be
    # used when calling the algorithm from another algorithm, or when
    # calling from the QGIS console.

    OUTPUT = 'OUTPUT'
    INPUT = 'INPUT'

    def initAlgorithm(self, config):
        """
        Here we define the inputs and output of the algorithm, along
        with some other properties.
        """
        
        fd_uri = '/vsicurl/https://storage.googleapis.com/skadesokonomi-dk-data/fdlayers.csv'
        fd_type = 'ogr'
        layer = QgsVectorLayer(fd_uri, 'fdlayers' , fd_type)

        self.options = {}
        for f in layer.getFeatures():
            self.options[f.attributes()[0]] = {'forklaring':f.attributes()[1],'adresse':f.attributes()[2],'dbkode':f.attributes()[3],'dato':f.attributes()[4]}
        self.option_list =[key for key in self.options]

        self.addParameter(QgsProcessingParameterEnum('import_layers', 'Choose types af data to import', [key for key in self.options], allowMultiple=True, defaultValue=[0]))

        self.addParameter(QgsProcessingParameterFeatureSource('layer_for_area_selection', 'Layer for area selection', types=[QgsProcessing.TypeVectorPolygon], defaultValue=None))

        self.addParameter(QgsProcessingParameterBoolean('open_layers_after_running_algorithm', 'Open layer(s) after running algorithm', defaultValue=False))

        param = QgsProcessingParameterProviderConnection('database_connection', 'Database connection', 'postgres', defaultValue='flood damage')
        param.setFlags(param.flags() | QgsProcessingParameterDefinition.FlagAdvanced)
        self.addParameter(param)
 
        param = QgsProcessingParameterDatabaseSchema('schema_name_for_parameter_list', 'schema name for parameter list', connectionParameterName='database_connection', defaultValue='fdc_admin')
        param.setFlags(param.flags() | QgsProcessingParameterDefinition.FlagAdvanced)
        self.addParameter(param)

        param = QgsProcessingParameterDatabaseTable('table_name_for_parameter_list', 'Table name for parameter list', connectionParameterName='database_connection', schemaParameterName='schema_name_for_parameter_list', defaultValue='parametre')
        param.setFlags(param.flags() | QgsProcessingParameterDefinition.FlagAdvanced)
        self.addParameter(param)


    def processAlgorithm(self, parameters, context, feedback):
        """
        Here is where the processing itself takes place.
        """
        user_options = self.parameterAsEnums(parameters, 'import_layers', context)
        selected_items = [self.option_list[i] for i in user_options]
        open_layer = self.parameterAsBoolean(parameters, 'open_layers_after_running_algorithm', context)

        # Get connection
        connection_name = self.parameterAsString(parameters, 'database_connection', context)
        metadata = QgsProviderRegistry.instance().providerMetadata('postgres')
        connection = metadata.findConnection(connection_name)

        # Find username/password (even if it's hidden in a configuration setup)
        uri = QgsDataSourceUri(connection.uri())
        #feedback.pushInfo('URI: {}'.format(uri.uri()))

        myname, mypass = self.get_postgres_conn_info(connection_name)
        uri.setUsername(myname)
        uri.setPassword(mypass)
        #feedback.pushInfo('Username = "{}", Password = "{}"'.format(myname,mypass))
        #feedback.pushInfo('URI(2): {}'.format(uri.uri()))

        # Find full name for table with parameters
        schema_name = self.parameterAsString(parameters, 'schema_name_for_parameter_list', context)
        table_name = self.parameterAsString(parameters, 'table_name_for_parameter_list', context)
        #feedback.pushInfo('Parameter: Schemaname = "{}", Tablename = "{}"'.format(schema_name,table_name))

        # Setup for progress indicator
        total = 100.0 / len(selected_items) if len(selected_items) else 0
        current = 1
        
        extr_result = {}

        # Get connection

        # Loop through selected layers        
        for item in selected_items:

            # Stop the algorithm if cancel button has been clicked
            if feedback.isCanceled():
                break
            
            feedback.pushInfo('\n\nProcessing layer {}....\n'.format(item))

            # Find schema and table name in parameter table
            #feedback.pushInfo('Export: SQL --> SELECT "value" FROM "{}"."{}" WHERE "name" = \'{}\''.format(schema_name, table_name, self.options[item]['dbkode']))
            parm_table = connection.executeSql('SELECT "value" FROM "{}"."{}" WHERE "name" = \'{}\''.format(schema_name, table_name, self.options[item]['dbkode']))
            full_name = parm_table[0][0] 

            # Split full name into schema and table name
            schtab = full_name.split('.',1)
            exp_schema = schtab[0].replace('"','')
            exp_table = schtab[1].replace('"','')

            #feedback.pushInfo('Export: Full name = {}, Schemaname = {}, Tablename = {}'.format(full_name, exp_schema, exp_table))

            # Find primary key column name in parameter table
            sql_pkey = 'SELECT "value" FROM "{}"."{}" WHERE "name" = \'f_pkey_{}\''.format(schema_name, table_name, self.options[item]['dbkode'])
            #feedback.pushInfo('Primary key: SQL --> {}'.format(sql_pkey))
            parm_table = connection.executeSql(sql_pkey)
            exp_pkey = parm_table[0][0].replace('"','') if parm_table[0] else None 
            
            #feedback.pushInfo('Primary: Column name: {}'.format(exp_pkey))

            # Find geometry column name in parameter table
            sql_geom = 'SELECT "value" FROM "{}"."{}" WHERE "name" = \'f_geom_{}\''.format(schema_name, table_name, self.options[item]['dbkode'])
            #feedback.pushInfo('Geometry: SQL --> {}'.format(sql_geom))
            parm_table = connection.executeSql(sql_geom)
            exp_geom = parm_table[0][0].replace('"','') if parm_table[0] else None
            
            #feedback.pushInfo('Geometry: Column name: {}'.format(exp_geom))


            # Drop table if it exist beforehand
            connection.executeSql('DROP TABLE IF EXISTS "{}"."{}"'.format(exp_schema, exp_table))

            # Update uri with datasource
            uri.setDataSource(exp_schema, exp_table, exp_geom, '', exp_pkey)
            uri_upd = 'postgres://'+uri.uri()

            feedback.pushInfo('Updated URI: {}'.format(uri_upd))


            feedback.pushInfo('Input ogr: {}'.format(self.options[item]['adresse']))

            # Activate processing algorithm with generated parameters
            processing.run(
                "native:extractbylocation", 
                {
                    'INPUT':     QgsVectorLayer(self.options[item]['adresse'],self.options[item]['dbkode'],'ogr'),
                    'PREDICATE': [0],
                    'INTERSECT': parameters['layer_for_area_selection'],
                    'OUTPUT':    uri_upd
                },
                is_child_algorithm=True, 
                context=context, 
                feedback=feedback
            )
            # Create spatial index
            connection.executeSql('CREATE INDEX ON "{}"."{}" USING GIST ("{}")'.format(exp_schema, exp_table, exp_geom))

            if open_layer:
                context.addLayerToLoadOnCompletion(
                    uri_upd,
                    QgsProcessingContext.LayerDetails(
                        item,
                        context.project(),
                        'LAYER'
                    )
                )

            # Update the progress bar
            feedback.setProgress(int(current* total))
            current += 1 

        return {'user_options': selected_items, 'connction_name': connection_name, 'schema_name': schema_name, 'table_name': schema_name}

    def name(self):
        """
        Returns the algorithm name, used for identifying the algorithm. This
        string should be fixed for the algorithm, and must not be localised.
        The name should be unique within each provider. Names should contain
        lowercase alphanumeric characters only and no spaces or other
        formatting characters.
        """
        return 'flood_damage_import_data'

    def displayName(self):
        """
        Returns the translated algorithm name, which should be used for any
        user-visible display of the algorithm name.
        """
        return self.tr('Flood Damage Import Data')

    def group(self):
        """
        Returns the name of the group this algorithm belongs to. This string
        should be localised.
        """
        return self.tr('Flood Damage')

    def groupId(self):
        """
        Returns the unique ID of the group this algorithm belongs to. This
        string should be fixed for the algorithm, and must not be localised.
        The group id should be unique within each provider. Group id should
        contain lowercase alphanumeric characters only and no spaces or other
        formatting characters.
        """
        return 'flood_damage'

    def tr(self, string):
        return QCoreApplication.translate('Processing', string)

    def createInstance(self):
        return FDDataImportAlgorithm()


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

