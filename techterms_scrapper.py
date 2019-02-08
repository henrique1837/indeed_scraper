# -*- coding: utf-8 -*-
"""
Created on Thu Feb  7 23:27:26 2019

@author: henrique
"""

import os
from pathlib import Path
from bs4 import BeautifulSoup
from goose3 import Goose
import requests
import pandas as pd
import time,datetime
import re
from dfply import *
from glob import glob
import string

#### Algorithm ####
## Set the directory ##
os.chdir(str(Path.home())+"/Documentos/scripts/indeed_scraper/")

## Prepare to get data ##
tec_words = list()
url_base = "https://techterms.com/list/"
for i in range(len(string.ascii_lowercase)):
    url = url_base + string.ascii_lowercase[i]
    page = requests.get(url)
    soup = BeautifulSoup(page.text, 'html.parser')
    table_words = soup.find(attrs={"class":"slist"})
    tr_words = table_words.find_all("tr")
    if(len(tr_words) > 0):
       for j in range(1,len(tr_words)):
         word = tr_words[j].find("a").text
         tec_words.append(word)


## Save data ##
df_struct =  {"word":tec_words}
df = pd.DataFrame(df_struct)
df.to_csv("results/tech_words_computer.csv")