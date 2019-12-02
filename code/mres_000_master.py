
"""

    DESCRIPTION:    Sets up environment for the data work of my MRes paper
    
    INFILES:        [None]
    
    OUTFILES:       [All]
    
    OUTPUTS:        [All]   
    
    LOG:            Created 02/12/2019
                    
"""

#Modules
import wrds

#Setting up the environment for querying Compustat from Python
db = wrds.Connection(wrds_username='adyevre')
db.create_pgpass_file()
db.close()                                                          #Testing whether it all works
db = wrds.Connection(wrds_username='adyevre')