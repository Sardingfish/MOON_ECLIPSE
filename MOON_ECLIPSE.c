#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
/* ****************************************************************
MOON_ECLIPSE.c :Compute Partial Eclipse begins Time(U1)
 
          Copyright (C) 2018 by DING Junsheng, All rights reserved.
 
   version :$Revision: 1.1 $ $Date: 2018/11/30 $
   history : 2018/11/30  1.0  new              
*******************************************************************/

extern void selconq_(char*,double*);
extern void iau_cal2jd_(int*,int*,int*,double*,double*,int*);
extern void iau_jd2cal_(double*,double*,int*,int*,int*,double*,int*);
extern void iau_pdp_(double*,double*,double*);
extern void sla_dd2tf_(int*,double*,char*,int*);   
extern void pleph_(double*,int*,int*,double*);

int main(int argc,char *argv[])
{
  double AU;                             /* Number of kilometers per astronomical unit (km) */
  double CLIGHT;                         /* Speed of light (km/s) */
  double ASUN;                           /* Radius of the sun (km) */
  double AM;                             /* Radius of the moon (km) */
  double RE;                             /* Radius of the earth"s equator (km) */
  int    DENUM;                          /* Vrision of DE EPHEMERIS */

  int    NCENT;                          /* INTEGER NUMBER OF CENTER POINT */
  int    NTARG;                          /* INTEGER NUMBER OF "TARGET" POINT */
  int    YEAR;                           /* year */
  int    MONTH;                          /* month */
  int    DAY;                            /* day */
  double DDAY;                           /* the fraction of a day */
  int    HOUR;                           /* hour */
  int    MINUTE;                         /* minute */
  double SECOND;                         /* second */
  double DJM0;                           /* MJD zero-point: always 2400000.5 */
  double DJM;                            /* Modified Julian Date for 0 hrs */
  double DJM_ALL;                        /* DJM0+DJM */

  double RRD[6];                         /* 6-WORD D.P. ARRAY CONTAINING POSITION AND VELOCITY OF POINT "NTARG" RELATIVE TO "NCENT" */
  double STE[3];                         /* ARRAY OF "EARTH" RELATIVE TO "SUN" */
  double ETO[3];                         /* ARRAY OF "Shadow cone" RELATIVE TO "EARTH" */
  double ETM[3];                         /* ARRAY OF "EARTH" RELATIVE TO "MOON" */
  double MTO[3];                         /* ARRAY OF "Shadow cone" RELATIVE TO "MOON" */
  double STM[3];                         /* ARRAY OF "MOON" RELATIVE TO "SUN" */

  double ANGLE_SEM;                      /* ANGLE OF Sun-Earth-Moon */
  double ANGLE_EOM;                      /* ANGLE OF Earth-ShadowCone-Moon */
  double ANGLE_EO;                       /* ANGLE OF Earth-ShadowCone */
  double ANGLE_MO;                       /* ANGLE OF Moon-ShadowCone */

  double PRODUCT;                        /* inner product */

  double DT0;                            /* light time lteration variable */
  double DT1;                            /* light time lteration variable */
  double vals;                           /* constant storage */
  char   nams[7];                        /* constant name */
  double ERR;                            /* angle error */
  double iteration_val=1.0/(24*3600);    /* 1 second to DJM */
  int    NDP=3;                          /* number of decimal places of seconds */
  int    IHMSF[4];                       /* hours, minutes, seconds, fraction */
  char   SIGN;                           /* "+" or "-" */

  int    J;                              /* status: 0 = OK */

/* Read constants from the ephemeris file ***************************************/

  printf("CONSTANTS...\n");

    strcpy( nams, "AU    ");
    selconq_(nams,&vals);
    printf("%9s%20.3f\n",nams,vals);
    AU=vals;

  strcpy( nams, "AM    ");
    selconq_(nams,&vals);
    printf("%9s%20.3f\n",nams,vals);
    AM=vals/AU;

  strcpy( nams, "RE    ");
    selconq_(nams,&vals);
    printf("%9s%20.3f\n",nams,vals);
    RE=(vals+65)/AU;

  strcpy( nams, "ASUN  ");
    selconq_(nams,&vals);
    printf("%9s%20.3f\n",nams,vals);
    ASUN=vals/AU;

  strcpy( nams, "DENUM ");
    selconq_(nams,&vals);
    printf("%9s%20.3f\n",nams,vals);
    DENUM=vals;

  strcpy( nams, "CLIGHT");
    selconq_(nams,&vals);
    printf("%9s%20.3f\n",nams,vals);
    CLIGHT=vals/AU;

/* Locate the most likely day *******************************************************/

    YEAR  = 2019;
    MONTH = 1;
    DAY   = 1;
    iau_cal2jd_( &YEAR, &MONTH, &DAY, &DJM0, &DJM, &J );

    do{
 
    NCENT = 11;     /* the sun */
    NTARG = 3;      /* the earth */

    DJM_ALL=DJM0+DJM; 
    pleph_(&DJM_ALL, &NCENT, &NTARG, RRD);  

    /* vector of the sun to the earth */
    STE[0] = RRD[0];                      
    STE[1] = RRD[1];
    STE[2] = RRD[2];

    NCENT  = 10;    /* the moon */
    NTARG  = 3;     /* the earth */
    pleph_(&DJM_ALL, &NCENT, &NTARG, RRD);

    /* vector of the moon the to earth */
    ETM[0] = RRD[0];            
    ETM[1] = RRD[1];
    ETM[2] = RRD[2];

    iau_pdp_(STE,ETM,&PRODUCT);
    ANGLE_SEM = acos(PRODUCT/(sqrt(STE[0]*STE[0]+STE[1]*STE[1]+STE[2]*STE[2])*sqrt(ETM[0]*ETM[0]+ETM[1]*ETM[1]+ETM[2]*ETM[2])));
    
    if     (ANGLE_SEM <= 2.92116)      DJM = DJM + 1.0;
    else if(ANGLE_SEM <= 3.01765)      DJM = DJM + 0.5;

    }while(ANGLE_SEM < 3.01765); 

/* Main body********************************************************************************/

  do
   {
    NCENT = 11;     /* the sun */
    NTARG = 3;      /* the earth */

/* Compute light time **********************************************************************/
    
    DJM_ALL=DJM0+DJM;
    pleph_(&DJM_ALL, &NCENT, &NTARG, RRD);
    DT1 = ((sqrt(RRD[0]*RRD[0]+RRD[1]*RRD[1]+RRD[2]*RRD[2])-ASUN-RE)*iteration_val)/CLIGHT;
    DT0 = 0;

    while(fabs(DT0-DT1)>1.16E-8)
    {
    DT0 = DT1;
    pleph_(&DJM_ALL, &NCENT, &NTARG, RRD);
    DT1 = ((sqrt(RRD[0]*RRD[0]+RRD[1]*RRD[1]+RRD[2]*RRD[2])-ASUN-RE)*iteration_val)/CLIGHT;
    }

/* Compute angles ***************************************************************************/
     
    /* vector of the sun to the earth */
    STE[0] = RRD[0];                      
    STE[1] = RRD[1];
    STE[2] = RRD[2];

    /* vector of the earth to the cone */
    ETO[0] = (RE/(RE-ASUN))*STE[0];      
    ETO[1] = (RE/(RE-ASUN))*STE[1];
    ETO[2] = (RE/(RE-ASUN))*STE[2];

    NCENT  = 10;    /* the moon */
    NTARG  = 3;     /* the earth */
    pleph_(&DJM_ALL, &NCENT, &NTARG, RRD);

    /* vector of the moon the to earth */
    ETM[0] = RRD[0];            
    ETM[1] = RRD[1];
    ETM[2] = RRD[2];

    /* vector of the moon the to cone */
    MTO[0] = ETO[0] - ETM[0];    
    MTO[1] = ETO[1] - ETM[1];
    MTO[2] = ETO[2] - ETM[2];

    /* angles */
    iau_pdp_(ETO,MTO,&PRODUCT);     
    ANGLE_EOM = acos(PRODUCT/(sqrt(ETO[0]*ETO[0]+ETO[1]*ETO[1]+ETO[2]*ETO[2])*sqrt(MTO[0]*MTO[0]+MTO[1]*MTO[1]+MTO[2]*MTO[2])));
    ANGLE_EO  = atan(RE/sqrt(ETO[0]*ETO[0]+ETO[1]*ETO[1]+ETO[2]*ETO[2]));
    ANGLE_MO  = atan(AM/sqrt(MTO[0]*MTO[0]+MTO[1]*MTO[1]+MTO[2]*MTO[2]));

    /* angle error */
    ERR = ANGLE_EOM - ANGLE_EO - ANGLE_MO;     
 
    /* DJM plus 1s */
    DJM = DJM+iteration_val;               
  
    /* loop exit condition */          

  }while(ERR > 0);  

/* Output the results ***************************************************/

  printf("RESULTS...\n"); 
  printf("LIGHT TIME:%15.3fsecond\n",DT1/iteration_val); 

  iau_jd2cal_( &DJM0, &DJM, &YEAR, &MONTH, &DAY, &DDAY, &J );

  DDAY=DDAY-(32.164+37.0)*iteration_val;             printf("%20.10f\n",DDAY);
  sla_dd2tf_(&NDP, &DDAY, &SIGN, IHMSF);    

  printf("Partial Eclipse begins(U1)\n");
  printf("%4d-%2d-%2d UTC Time: %2d:%2d:%6.3f\n",YEAR,MONTH,DAY,IHMSF[0],IHMSF[1],IHMSF[2]+IHMSF[3]/1000.0);                
  
  printf("ANGLE_EOM =%20.10f\nANGLE_EO  =%20.10f\nANGLE_MO  =%20.10f\n",ANGLE_EOM,ANGLE_EO,ANGLE_MO);
  
return 0;
}
