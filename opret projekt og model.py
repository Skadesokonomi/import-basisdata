from sqlalchemy import create_engine, text

db_parameters = 'postgresql://postgres:ukulemy@localhost:5435/tgv_18'
project_name = 'Markby'
wkt = 'MultiPolygon (((727337.14333881 6163949.53417956, 727795.71684437 6164209.89600394, 728048.46844713 6164773.51362908, 728434.97546012 6164315.97788101, 728196.98307504 6163842.76046416, 728158.24012863 6163800.32771333, 727742.21468028 6163552.64959165, 727720.53707932 6163596.00479358, 727560.03058705 6163570.63738819, 727510.67945294 6163555.18633218, 727337.14333881 6163949.53417956)))'
model_name = 'Initial data'
parameter_name = 'default'
original = True

print ('Starting... ')
engine = create_engine(db_parameters)

with engine.connect() as conn:
    print ('Creating project... ')
    sql = "SELECT tgv_functions.projects_create('{}','{}',{})".format(project_name, wkt, 25832)
    print(sql)
    result = conn.execute(text(sql))

    print ('Creating model... ')
    sql = "SELECT tgv_functions.models_create('{}','{}',{},'{}')".format(project_name, model_name, original, parameter_name)
    print(sql)
    result = conn.execute(text(sql))

    conn.commit()