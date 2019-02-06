# -*- coding: utf-8 -*-
"""
Created on Sun Jan 27 19:50:43 2019

@author: henrique
"""
### Packages ####

import os
from pathlib import Path
from bs4 import BeautifulSoup
from goose3 import Goose
import requests
import pandas as pd
import time,datetime
import re
from dfply import *
# import ftfy as ftfy
# import locale as locale
from glob import glob
#from newspaper import Article

#del(diamonds)
#del(name)
#del(verb)

#### Indeed scrap ####

## Functions ##
def indeed_scraper(query = "ethereum"):
    df_final = pd.DataFrame()
    url_base = "https://www.indeed.com"
    start = 0
    ## Unfortunately 180 is the maximum ##
    while(start < 180):
        url = "https://www.indeed.com/jobs?q="+query+"&sort=date&start="+str(start)
        companies = list()
        locations = list()
        dates = list()
        short_descriptions = list()
        jobs_title = list()
        sallaries = list()
        links = list()
        page = requests.get(url)
        soup = BeautifulSoup(page.text, 'html.parser')
        ## Get the td that have the jobs ##
        td_results = soup.find_all(attrs={"id":"resultsCol"})
        div_jobs = td_results[0].find_all(attrs={"class":"jobsearch-SerpJobCard"})
        ## For each job insert attributes in lists and then make a dataframe 
        for i in range(len(div_jobs)):
            ## If has no date we will not get this job now ##
            date = div_jobs[i].find(attrs={"class":"date"})
            if(date != None):
                dates.append(date.text)
                company = div_jobs[i].find(attrs={"class":"company"})
                companies.append(company.text)
                location = div_jobs[i].find(attrs={"class":"location"})
                locations.append(location.text)
                short_descript = div_jobs[i].find(attrs={"class":"summary"})
                short_descriptions.append(short_descript.text)
                title = div_jobs[i].find(attrs={"class":"jobtitle"})
                jobs_title.append(title.text)
                ## Some jobtitle class are not tag a 
                if(title.find("a") != None):
                    link = title.find("a")
                    link = link["href"]
                else:
                    link = title["href"]
                ## Verify link ##
                if(url_base not in link):
                    links.append(url_base+link)
                else:
                    links.append(title["href"])
                sallary = div_jobs[i].find(attrs={"class":"salary"})
                ## There are jobs that do not have sallary in this section ##
                if(sallary != None):
                    sallaries.append(sallary.text)
                else:
                    sallaries.append("")
        ## Prepare dataframe ##
        df_struct = {"link":links,
                     "date":dates,
                     "title":jobs_title,
                     "company":companies,
                     "location":locations,
                     "summary":short_descriptions,
                     "sallary":sallaries}
        df = pd.DataFrame(df_struct)
        df_final = df_final.append(df)
        print("Page "+str(int(start/10)+1)+" scraped")
        start = start + 10
    df_final = df_final.reset_index()
    return(df_final)
    
def extract_description(links):
    descriptions = list()
    g = Goose()
    for i in range(len(links)):
        description = g.extract(links[i])
        descriptions.append(description.cleaned_text)
        print("Got description "+str(i+1)+" of "+str(len(links)))
    return({"description":descriptions})

#### Algorithm ####
## Set the directory ##
os.chdir(str(Path.home())+"/Documentos/scripts/indeed_scraper/")
## First make the scrap ##
df_final = indeed_scraper(query="ethereum")
## Extract full description of jobs ##
jobs_desc = extract_description(df_final.link)
df_final["text"] = jobs_desc["description"]
## Save results for future analysis and data treatment ##
# To simplify it will be saved as csv (but could be json or even inserted in a database)
# with the time of "today" to make future analysis
df_final.to_csv("results/"+str(datetime.datetime.today())+"_scrap_indeedJobs.csv")

## Now you can use R or python to make data analysis (next step)