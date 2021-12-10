*************** Importing Data ***************;
LIBNAME Sherin "C:\\D Drive\\Data Science\\15. SAS Project\\Project\\Library";

PROC IMPORT OUT= Sherin.car_accident_data 
            DATAFILE= "C:\\D Drive\\Data Science\\15. SAS Project\\Project\\Data Set\\Car accidents data 2017.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

********************************************* DATA PROFILING - NUMERIC *********************************************************;

%MACRO DATA_PROFILING (SAS_LIB_PATH =  ,DSN = ,DATA_FILE_PATH = );

*Setting the library Name;
LIBNAME Sherin &SAS_LIB_PATH;

*Importing Data;
PROC IMPORT OUT= Sherin.&DSN. 
            DATAFILE= &DATA_FILE_PATH.
            DBMS=CSV REPLACE;
		    GETNAMES=YES;
		    DATAROW=2; 
		    GUESSINGROWS=100; 
RUN;

*Data Profiling and creating table;
PROC CONTENTS DATA = Sherin.&DSN. OUT= Sherin.&DSN._PROJECT_VARS;RUN;

*Creating list of 'Numerical' variables from table;
PROC SQL;
	SELECT NAME INTO : NUM_ONLY SEPARATED BY " "
	FROM Sherin.&DSN._PROJECT_VARS
	WHERE TYPE EQ 1
	;
QUIT;

*Creating list of 'Categorical' variables from table;
PROC SQL;
	SELECT NAME INTO : CHAR_ONLY SEPARATED BY " "
	FROM Sherin.&DSN._PROJECT_VARS
	WHERE TYPE EQ 2
    ;
QUIT;

*Looping of 'Numerical' variables;
%LET N1 = %SYSFUNC(COUNTW(&NUM_ONLY));

%DO I = 1 %TO &N1;
	%LET X = %SCAN(&NUM_ONLY,&I);
	ODS PDF FILE = "C:\\D Drive\\Data Science\\15. SAS Project\\Project\\PDF\\Data Profiling\\DATA_PROFILING_&X._&SYSDATE9..PDF";
	TITLE "DISTRIBUTION OF NUMERIC VARIABLE : &X.";
		PROC MEANS DATA = Sherin.&DSN N NMISS MIN MEDIAN MEAN MAX STD MAXDEC=2;
		 VAR &X.;
		RUN;
	TITLE "GRAPHIC DISTRIBUTION OF NUMERIC VARAIBLE : &X.";
		PROC SGPLOT DATA = Sherin.&DSN.;
		 HISTOGRAM &X.;
		 DENSITY &X./TYPE = KERNEL;
		KEYLEGEND / LOCATION=INSIDE POSITION=TOPRIGHT ACROSS=1 NOBORDER;
		RUN;
	QUIT;

	TITLE "GRAPHIC DISTRIBUTION (VERTICAL BAR) OF NUMERIC VARAIBLE : &X.";
		PROC SGPLOT DATA = Sherin.&DSN.;
		 VBOX &X.;
		 yaxis grid;
		 xaxis display=(nolabel);
		RUN;
		QUIT;
	ODS PDF CLOSE;
%END;

*Looping of 'Categorical' variables;
%LET N2 = %SYSFUNC(COUNTW(&CHAR_ONLY));
%DO I = 1 %TO &N2;
	%LET X = %SCAN(&CHAR_ONLY,&I);
	ODS PDF FILE = "C:\\D Drive\\Data Science\\15. SAS Project\\Project\\PDF\\Data Profiling\\DATA_PROFILING_&X._&SYSDATE9..PDF";

	TITLE "THIS IS FREQUENCY DISTRIBUTION OF CATEGORIC VARIABLE : &X.";
	  PROC FREQ DATA=Sherin.&DSN.;
	  TABLE &X.;
	  RUN;

	TITLE "THIS IS VERTICAL BARCHART OF CATEGORIC VARIABLE : &X.";
	  PROC SGPLOT DATA = Sherin.&DSN.;
      VBAR &X.;
      STYLEATTRS 
      BACKCOLOR=LIBG 
      WALLCOLOR=CREAM
      ;
      RUN;
    ODS PDF CLOSE;
%END;
%MEND;

%DATA_PROFILING 
(SAS_LIB_PATH = "C:\\D Drive\\Data Science\\15. SAS Project\\Project\\Library" ,
DSN =car_accident_data ,
DATA_FILE_PATH = "C:\\D Drive\\Data Science\\15. SAS Project\\Project\\Data Set\\Car accidents data 2017.csv");


********************************* EDA STEPS ************************;
/*
Numeric Variables:
1. Day			- Need to be Formatted
2. Hour			- Need to be Formatted
3. Longitude
4. Latitude

Categoric Variables:
1. District Name
2. Neighborhood Name
3. Street
4. Weekday
5. Month
6. Part of the day
7. Mild injuries		- Need to be Formatted
8. Serious injuries		- Need to be Formatted
9. Victims				- Need to be Formatted
10.Vehicles involved	- Need to be Formatted
;

## Y Variable : Victims;
*/

* Format for the catergotical variables;
PROC FORMAT;
 VALUE mildInjuriesGrp
	    low-<5 = "<=4"
		5- <8  = "5-7"
		8-high = ">=8"
	    ;
 VALUE seriousInjuriesGrp
		0 = "0"
        1 = "1"
		2 = "2"
		3 = "3"
		4 = "4"
	    ;
 VALUE victimsGrp
	    low-<2 = "<=1"
        2- <4 = "2-3"
		4- <6 = "4-5"
		6-high = ">=6"
	    ;
 VALUE vehiclesInvGrp
	    low-<4 = "<=3"
		4- <8  = "4-7"
		8-12 = "8-11"
		12-high = ">=12"
	    ;
VALUE dayGrp
	    low-<11 = "Start of Month"
		11- <21  = "Mid of Month"
		21-high = "End of Month"
	    ;
VALUE hourGrp
	    low-<6 = "12AM - 6AM"
		6-<12 = "6AM - 12PM"
		12- <18  = "12PM - 6PM"
		18-high = "6PM - 12AM"
	    ;
RUN;



* Creating new table with modified fields;
Data Sherin.A1_Adjusted;
SET Sherin.car_accident_data;
*Day = put(Day,2.);
FORMAT  Serious_injuries seriousInjuriesGrp.
		Mild_injuries mildInjuriesGrp.
		Victims victimsGrp.
		Vehicles_involved vehiclesInvGrp.
		Hour hourGrp.
		Day dayGrp.
		;
drop Id;
RUN;

proc print data=Sherin.A1_Adjusted(obs=5);run;

********************************** DATA CLEANING **********************************;

/* create a format to group missing and nonmissing */
proc format;
 value $missfmt ' '='Missing' other='Not Missing';
 value  missfmt  . ='Missing' other='Not Missing';
run;
 
proc freq data=Sherin.A1_Adjusted; 
format _CHAR_ $missfmt.; /* apply format for the duration of this PROC */
tables _CHAR_ / missing missprint nocum nopercent;
format _NUMERIC_ missfmt.;
tables _NUMERIC_ / missing missprint nocum nopercent;
run;

/* 1. There are no missing values in the columns
   2. But need to fix the "Unknown" value in "District Name" and "Neighborhood Name" 
*/

* Fix "Unknown" value in "District Name" by taking MODE;

PROC SQL;
Create Table Dist_Table as
select District_Name, Count(District_Name) as Count
from Sherin.A1_Adjusted
group by District_Name;
QUIT;

PROC SQL;
Select District_Name into :DISTRICT_MODE from Dist_Table where Count = (select max(Count) from Dist_Table);
QUIT;

* Fix "Unknown" value in "Neighborhood Name" by taking MODE;

PROC SQL;
Create Table Neighbor_Table as
select Neighborhood_Name, Count(Neighborhood_Name) as Count
from Sherin.A1_Adjusted
group by Neighborhood_Name;
QUIT;

PROC SQL;
Select Neighborhood_Name into :NEIGHBOR_MODE from Neighbor_Table where Count = (select max(Count) from Neighbor_Table);
QUIT;

*DATA STEP TO PRODUCE THE FINAL OUTPUT TABLE;
Data Sherin.Accident_Data_Final;
SET Sherin.A1_Adjusted;
 District_Name=tranwrd(District_Name,"Unknown","&DISTRICT_MODE");
 Neighborhood_Name=tranwrd(Neighborhood_Name,"Unknown","&NEIGHBOR_MODE");
RUN;

proc print data=Sherin.Accident_Data_Final(obs=10);run;

********************************** CREATING MACRO FOR UNIVARIATE ANALYSIS **********************************;

%MACRO UNIVARIATE_ANALYSIS(DSN = );

*Data Profiling and creating table;
PROC CONTENTS DATA = Sherin.&DSN. OUT= Sherin.&DSN._MOD_VARS;RUN;

*Creating list of 'Numerical' variables from table;

PROC SQL;
	SELECT NAME INTO : MOD_NUM_ONLY SEPARATED BY " "
	FROM Sherin.&DSN._MOD_VARS
	WHERE Format EQ "BEST"
	;
QUIT;

*Creating list of 'Categorical' variables from table;
PROC SQL;
	SELECT NAME INTO : MOD_CHAR_ONLY SEPARATED BY " "
	FROM Sherin.&DSN._MOD_VARS
	WHERE Format NOT EQ "BEST"
	;
QUIT;

***** Looping of 'CATEGORIC' variables *****;

%LET N1 = %SYSFUNC(COUNTW(&MOD_CHAR_ONLY));
%DO I = 1 %TO &N1;
	%LET X = %SCAN(&MOD_CHAR_ONLY,&I);
	ODS PDF FILE = "C:\\D Drive\\Data Science\\15. SAS Project\\Project\\PDF\\UniVariate\\Univariate_&X._&SYSDATE9..PDF";
		
		*CREATING FREQUENCY TABLE;
		TITLE "COUNT BY : &X.";
			PROC FREQ DATA = Sherin.&DSN.;
			 TABLE &X./MISSING;
			RUN;

		*CREATING VERTICAL BAR PLOT;
		TITLE "COUNT BY : &X.";
			PROC SGPLOT DATA = Sherin.&DSN.;
			 VBAR &X./categoryorder=respDESC barwidth=0.6 fillattrs=graphdata4 ;
			 *xaxis display=(nolabel);
			 xaxis display=(nolabel noline noticks); 
             yaxis display=(noline noticks) grid;
			 STYLEATTRS BACKCOLOR=SALMON;
			RUN;
			QUIT;

		*CREATING PIE CHART;
			PROC TEMPLATE; 
			DEFINE STATGRAPH PIE;  
			BEGINGRAPH;    
			ENTRYTITLE "COUNT BY : &X.";  
			LAYOUT REGION;      
			PIECHART CATEGORY=&X. / DATALABELLOCATION=OUTSIDE DATASKIN = CRISP  
                DATALABELCONTENT = ALL CATEGORYDIRECTION = CLOCKWISE START = 180 NAME = 'pie' ; 
			DISCRETELEGEND 'pie'; 
			ENDLAYOUT;  
			ENDGRAPH; 
			END; 
			RUN; 
			PROC SGRENDER DATA = Sherin.&DSN. TEMPLATE = PIE;
			RUN;

    ODS PDF CLOSE;
%END;

***** Looping of 'NUMERICAL' variables *****;

%LET N2 = %SYSFUNC(COUNTW(&MOD_NUM_ONLY));
%DO I = 1 %TO &N2;
	%LET X = %SCAN(&MOD_NUM_ONLY,&I);
	ODS PDF FILE = "C:\\D Drive\\Data Science\\15. SAS Project\\Project\\PDF\\UniVariate\\Univariate_&X._&SYSDATE9..PDF";

		*DISTRIBUTION OF NUMERIC VARIABLE;
		TITLE "DISTRIBUTION OF : &X.";
			PROC MEANS DATA = Sherin.&DSN. N NMISS MIN MEDIAN MEAN MAX STD MAXDEC=2;
			 VAR &X.;
			RUN;

		*CREATING HISTOGRAM AND DENSITY CURVE;
		TITLE "DISTRIBUTION OF NUERMIC VARIABLE &X.: HISTOGRAM AND DENSITY CURVE";
			PROC SGPLOT DATA =  Sherin.&DSN. ;
			 HISTOGRAM &X.;
			 DENSITY &X.;
			 DENSITY &X. / TYPE=KERNEL;
			 KEYLEGEND / LOCATION=INSIDE POSITION=TOPRIGHT ACROSS=1 NOBORDER;
			RUN;
			QUIT;

		*CREATING VERTICAL BOX-PLOT;
		TITLE "DISTRIBUTION OF NUMERIC VARIABLE &X. : VERTICAL BOX-PLOT";
			PROC SGPLOT DATA = Sherin.&DSN.  ;
			 VBOX &X.;
			 yaxis grid;
			 xaxis display=(nolabel);
			RUN;
			QUIT;

    ODS PDF CLOSE;
%END;

%MEND;


%UNIVARIATE_ANALYSIS (DSN = Accident_Data_Final);


********************************** MACRO FOR BIVARIATE ANALYSIS **********************************;


%MACRO BIVARIATE_ANALYSIS(DSN=, target=);
  
*Creating list of 'Categorical' variables except the "TARGET" from table;
	PROC SQL;
		SELECT NAME INTO : MOD_CHAR_ONLY SEPARATED BY " "
		FROM Sherin.&DSN._MOD_VARS
		WHERE Format NOT EQ "BEST" AND NAME NOT EQ "&target."
		;
	QUIT;

*Creating list of 'Numerical' variables from table;

	PROC SQL;
		SELECT NAME INTO : MOD_NUM_ONLY SEPARATED BY " "
		FROM Sherin.&DSN._MOD_VARS
		WHERE Format EQ "BEST"
		;
	QUIT;

***** Looping of 'CATEGORIC' variables VS TARGET (CHI-SQAURE)*****;

%LET N1 = %SYSFUNC(COUNTW(&MOD_CHAR_ONLY));
%DO I = 1 %TO &N1;
	%LET X = %SCAN(&MOD_CHAR_ONLY,&I);
		  ODS PDF FILE = "C:\\D Drive\\Data Science\\15. SAS Project\\Project\\PDF\\BiVariate\\Bivariate_&X. & &target._&SYSDATE9..PDF";
			TITLE "RELATIONSHIP BETWEEN &X. & &target.";
				PROC FREQ DATA = Sherin.&DSN.;
					*TABLE &X. * &target./ CHISQ MISSING NOCOL NOROW;
					TABLE &X. * &target./CHISQ NOROW NOCOL PLOTS=FREQPLOT(TWOWAY=STACKED SCALE=GROUPPCT) ;
				RUN;
			TITLE "VERTICAL BAR CHART FOR &X. & &target.";
					PROC SGPLOT DATA = Sherin.&DSN.;
					 VBAR &X./group = &target. groupdisplay=cluster;
					 xaxis display=(nolabel noline noticks) grid; 
                     yaxis display=(noline noticks) grid;
					RUN;
				QUIT;			

	      ODS PDF CLOSE;
%END;

***** Looping of 'NUMERICAL' variables VS TARGET *****;

%LET N2 = %SYSFUNC(COUNTW(&MOD_NUM_ONLY));
%DO I = 1 %TO &N2;
	%LET X = %SCAN(&MOD_NUM_ONLY,&I);
		  ODS PDF FILE = "C:\\D Drive\\Data Science\\15. SAS Project\\Project\\PDF\\BiVariate\\Bivariate_&X. & &target._&SYSDATE9..PDF";
		  TITLE "VERTICAL BOX PLOT OF &X. & &target.";
			PROC SGPLOT DATA =Sherin.&DSN.;
			VBOX &X./GROUP =&target.;
			RUN;
			QUIT;			
	      ODS PDF CLOSE;
%END;

%MEND;

%BIVARIATE_ANALYSIS(DSN=Accident_Data_Final, target=Victims);

*PLOTTING THE SERIOUS INJURIES VS LATITUDE AND LONGITUDE;
TITLE "SCATTER PLOT : Longitude & Latitude ACROSS Victims";
PROC SGPANEL DATA =Sherin.Accident_Data_Final;
 PANELBY Victims/ SPACING =5;
 SCATTER X= Longitude Y=Latitude/GROUP= Victims;
 RUN;
 QUIT;

 *PLOTTING HORIZONDAL BAR CHART FOR THE NEIGHBORHOOD NAME VARIABLE;
TITLE "COUNT BY : Neighborhood_Name";
 PROC SGPLOT DATA = Sherin.Accident_Data_Final;
  hBAR Neighborhood_Name/categoryorder=respDESC barwidth=0.6 fillattrs=graphdata4 ;
  xaxis display=(nolabel noline noticks) grid; 
  yaxis display=(noline noticks) grid;
  STYLEATTRS BACKCOLOR=SALMON;
RUN;
QUIT;

TITLE "COUNT BY : Neighborhood_Name & Victims";
 PROC SGPLOT DATA = Sherin.Accident_Data_Final;
  hBAR Neighborhood_Name/group = Victims categoryorder=respDESC barwidth=0.6 fillattrs=graphdata4 ;
  xaxis display=(nolabel noline noticks) grid; 
  yaxis display=(noline noticks) grid;
  STYLEATTRS BACKCOLOR=SALMON;
RUN;
QUIT;

 ************************************************ Modelling ******************************************************;

Data Sherin.Accident_Data_Model;
SET Sherin.Accident_Data_Final;
drop Day Part_of_the_day Street Longitude Latitude;
Run;

Proc print data= Sherin.Accident_Data_Model(obs=5);Run;


proc logistic data = Sherin.Accident_Data_Model plots(only) =(roc oddsratio);
  class District_Name(PARAM =REF REF ="Eixample")
		Neighborhood_Name (PARAM =REF REF ="la Dreta de l'Eixample")
		Weekday (PARAM =REF REF ="Sunday")
		Month (PARAM =REF REF ="November")
		Hour (PARAM =REF REF ="12AM - 6AM")
		Mild_injuries (PARAM =REF REF ="<=4")
		Serious_injuries (PARAM =REF REF ="2")
		Vehicles_involved (PARAM =REF REF =">=12")
        ;
   model Victims(EVENT=">=6") = District_Name Neighborhood_Name Weekday Month
                                  Hour Mild_injuries Serious_injuries Vehicles_involved / CLODDS =PL;
   output out=preds predprobs=individual;
run;
QUIT;

proc freq data=preds;
        table Victims*_INTO_ / out=CellCounts NOCOL NOROW;
        run;
data CellCounts;
  set CellCounts;
  Victims2 = put(Victims,VICTIMSGRP.);
  Match=0;
  if Victims2 = _INTO_ then Match=1;
run;

proc means data=CellCounts mean;
  freq count;
  var Match;
run;

***************************** testing*********************************;

proc print data=Sherin.car_accident_data(obs=10);Run;

PROC SGPANEL DATA =Sherin.Accident_Data_Final;
 PANELBY serious_injuries/ SPACING =5;
 SCATTER X= Victims Y=Vehicles_involved;
 RUN;
 QUIT;

 PROC CORR DATA = Sherin.Accident_Data_Final pearson spearman PLOTS(MAXPOINTS=NONE)
          PLOTS= matrix(histogram);
 VAR Victims Vehicles_involved ;
RUN;

proc contents data=Sherin.Accident_Data_Model;Run;
