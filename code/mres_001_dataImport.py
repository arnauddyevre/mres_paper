
"""

    DESCRIPTION:    Imports segment data from compustat
                    Creates network datasets for these years
    
    INFILES:        Compustat segment data, 1965-2018
    
    OUTFILES:       Adjacency matrices for the years 1965-2018
                    In .csv
    
    OUTPUTS:        [None]   
    
    LOG:            Created 02/12/2019
                    
"""

#Packages
from pathlib import Path
import pandas as pd

#Paths
orig = Path("C:/Users/dyevre/Documents/mres_paper/orig")

#Importing the Compustat data
importCompustat = orig / "compustat_segment_customer_76_19.csv"
df = pd.read_csv (importCompustat)
print (df)


print(importCompustat.read_text())






