#!/bin/bash
mkdir temp_crossimid
mv codelists/crossimid* temp_crossimid/
cohortextractor update_codelists
mv temp_crossimid/* codelists/
rm -r temp_crossimid
