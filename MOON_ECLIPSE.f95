PROGRAM MOON_ECLIPSE
  IMPLICIT NONE

! MOON_ECLIPSE.f95 :Compute Partial Eclipse begins Time(U1)
! 
!          Copyright (C) 2018 by DING Junsheng, All rights reserved.
! 
! version :$Revision: 1.1 $ $Date: 2018/11/25 $
! history : 2018/11/25  1.0  new
!         : 2018/12/15  1.1  add light time from moon to earth
!         : 2018/12/24  1.2  fixed the order of NTARG and NCENT in the parameter list

  REAL *8 :: AU                             !Number of kilometers per astronomical unit (km)
  REAL *8 :: CLIGHT                         !Speed of light (km/s)
  REAL *8 :: ASUN                           !Radius of the sun (km)
  REAL *8 :: AM                             !Radius of the moon (km)
  REAL *8 :: RE                             !Radius of the earth's equator (km)
  INTEGER :: DENUM                          !Vrision of DE EPHEMERIS

  INTEGER :: NCENT                          !INTEGER NUMBER OF CENTER POINT
  INTEGER :: NTARG                          !INTEGER NUMBER OF 'TARGET' POINT
  INTEGER :: YEAR                           !year
  INTEGER :: MONTH                          !month
  INTEGER :: DAY                            !day
  REAL *8 :: DDAY                           !the fraction of a day
  INTEGER :: HOUR                           !hour
  INTEGER :: MINUTE                         !minute
  REAL *8 :: SECOND                         !second
  REAL *8 :: DJM0                           !MJD zero-point: always 2400000.5
  REAL *8 :: DJM                            !Modified Julian Date for 0 hrs

  REAL *8,DIMENSION(6) :: RRD               !6-WORD D.P. ARRAY CONTAINING POSITION AND VELOCITY OF POINT 'NTARG' RELATIVE TO 'NCENT'
  REAL *8,DIMENSION(3) :: STE               !ARRAY OF 'EARTH' RELATIVE TO 'SUN'
  REAL *8,DIMENSION(3) :: ETO               !ARRAY OF 'Shadow cone' RELATIVE TO 'EARTH'
  REAL *8,DIMENSION(3) :: MTE               !ARRAY OF 'EARTH' RELATIVE TO 'MOON'
  REAL *8,DIMENSION(3) :: MTO               !ARRAY OF 'Shadow cone' RELATIVE TO 'MOON'
  REAL *8,DIMENSION(3) :: STM               !ARRAY OF 'MOON' RELATIVE TO 'SUN'

  REAL *8 :: ANGLE_SEM                      !ANGLE OF Sun-Earth-Moon
  REAL *8 :: ANGLE_EOM                      !ANGLE OF Earth-ShadowCone-Moon
  REAL *8 :: ANGLE_EO                       !ANGLE OF Earth-ShadowCone
  REAL *8 :: ANGLE_MO                       !ANGLE OF Moon-ShadowCone
  REAL *8 :: PRODUCT                        !inner product 

  REAL *8 :: DT0                            !light time lteration variable 
  REAL *8 :: DT1                            !light time lteration variable
  REAL *8 :: vals                           !constant storage
  CHARACTER*6 :: nams                       !constant name
  REAL *8 :: ERR                            !angle error
  REAL *8 :: iteration_val=1.0/(24*3600)    !1 second to DJM
  INTEGER :: NDP=3                          !number of decimal places of seconds
  INTEGER ,DIMENSION(4) :: IHMSF            !hours, minutes, seconds, fraction
  CHARACTER :: SIGN                         !'+' or '-'

  INTEGER :: J                              !status: 0 = OK

! Read constants from the ephemeris file ***************************************

  WRITE(*,80)
  80 FORMAT(//,'CONSTANTS...',/)

  nams='AU'
    CALL selconQ(nams,vals)
    WRITE(*,'(A9,F20.3)')nams,vals
    AU=vals

  nams='AM'
    CALL selconQ(nams,vals)
    WRITE(*,'(A9,F20.3)')nams,vals
    AM=vals/AU

  nams='RE'
    CALL selconQ(nams,vals)
    WRITE(*,'(A9,F20.3)')nams,vals
    RE=(vals+65D0)/AU

  nams='ASUN'
    CALL selconQ(nams,vals)
    WRITE(*,'(A9,F20.3)')nams,vals
    ASUN=vals/AU

  nams='DENUM'
    CALL selconQ(nams,vals)
    WRITE(*,'(A9,F20.3)')nams,vals
    DENUM=vals

  nams='CLIGHT'
    CALL selconQ(nams,vals)
    WRITE(*,'(A9,F20.3)')nams,vals
    CLIGHT=vals/AU

! Locate the most likely day *******************************************************

    YEAR  = 2019
    MONTH = 1
    DAY   = 1
    CALL iau_CAL2JD ( YEAR, MONTH, DAY, DJM0, DJM, J )

    DO

    NCENT = 11     !the sun
    NTARG = 3      !the earth

    CALL PLEPH(DJM0+DJM, NTARG, NCENT, RRD)

    ! vector of the sun to the earth
    STE(1) = RRD(1)                      
    STE(2) = RRD(2)
    STE(3) = RRD(3)

    NCENT  = 10    ! the moon
    NTARG  = 3     ! the earth
    CALL PLEPH(DJM0+DJM, NTARG, NCENT, RRD)

    ! vector of the moon the to earth
    MTE(1) = RRD(1)            
    MTE(2) = RRD(2)
    MTE(3) = RRD(3)

    CALL iau_PDP (STE,MTE,PRODUCT)
    ANGLE_SEM = ACOS(PRODUCT/(SQRT(STE(1)**2+STE(2)**2+STE(3)**2)*SQRT(MTE(1)**2+MTE(2)**2+MTE(3)**2)))
    !WRITE(*,*)ANGLE_SEM

    IF(ANGLE_SEM.LE.2.92116) THEN
      DJM = DJM + 1.0
    ELSE IF(ANGLE_SEM.LE.3.01765) THEN
      DJM = DJM + 0.5
    ELSE
      EXIT
    END IF

    END DO

! Main body********************************************************************************

  DO
    NCENT = 11     !the sun
    NTARG = 3      !the earth

! Compute light time **********************************************************************

    CALL PLEPH(DJM0+DJM, NTARG, NCENT, RRD)
    DT1 = ((SQRT(RRD(1)**2+RRD(2)**2+RRD(3)**2)-ASUN-RE)*iteration_val)/CLIGHT
    DT0 = 0.

    DO WHILE(ABS(DT0-DT1)>1.16E-8)
    DT0 = DT1
    CALL PLEPH(DJM0+DJM-DT0, NTARG, NCENT, RRD)
    DT1 = ((SQRT(RRD(1)**2+RRD(2)**2+RRD(3)**2)-ASUN-RE)*iteration_val)/CLIGHT
    END DO

! Compute angles ***************************************************************************
     
    ! vector of the sun to the earth
    STE(1) = RRD(1)                      
    STE(2) = RRD(2)
    STE(3) = RRD(3)

    ! vector of the earth to the cone
    ETO(1) = (RE/(RE-ASUN))*STE(1)      
    ETO(2) = (RE/(RE-ASUN))*STE(2)
    ETO(3) = (RE/(RE-ASUN))*STE(3)

    NCENT  = 10    ! the moon
    NTARG  = 3     ! the earth
    CALL PLEPH(DJM0+DJM, NTARG, NCENT, RRD)

    ! vector of  the moon to the earth
    MTE(1) = RRD(1)            
    MTE(2) = RRD(2)
    MTE(3) = RRD(3)

    ! vector of the moon to the cone
    MTO(1) = ETO(1) - MTE(1)    
    MTO(2) = ETO(2) - MTE(2)
    MTO(3) = ETO(3) - MTE(3)

    ! angles
    CALL iau_PDP (ETO,MTO,PRODUCT)     
    ANGLE_EOM = ACOS(PRODUCT/(SQRT(ETO(1)**2+ETO(2)**2+ETO(3)**2)*SQRT(MTO(1)**2+MTO(2)**2+MTO(3)**2)))
    ANGLE_EO  = ATAN(RE/SQRT(ETO(1)**2+ETO(2)**2+ETO(3)**2))
    ANGLE_MO  = ATAN(AM/SQRT(MTO(1)**2+MTO(2)**2+MTO(3)**2))

    ! angle error
    ERR = ANGLE_EOM - ANGLE_EO - ANGLE_MO     
 
    ! loop exit condition
    IF(ERR.LE.0D0) EXIT              

    ! DJM plus 1s
    DJM = DJM+iteration_val               
    
  END DO

    ! Plus ligth time from the moon to the earth
    DJM = DJM + ((SQRT(RRD(1)**2+RRD(2)**2+RRD(3)**2)-AM-RE)*iteration_val)/CLIGHT

! Output the results ***************************************************

  WRITE(*,85)
  85 FORMAT(//,'RESULTS...')

  WRITE(*,90)DT1/iteration_val
  90 FORMAT(/,' LIGHT TIME: ',F15.3,' second',/)

  !CALL iau_TTTAI ( TT1, TT2, DJM0, DJM, J )
  CALL iau_JD2CAL ( DJM0, DJM, YEAR, MONTH, DAY, DDAY, J )

  DDAY=DDAY-(32.184+37)*iteration_val                       
  CALL sla_DD2TF (NDP, DDAY, SIGN, IHMSF)                    
  WRITE(*,*)'Partial Eclipse begins(U1)'
  WRITE(*,100) YEAR,MONTH,DAY,IHMSF(1),IHMSF(2),IHMSF(3)+IHMSF(4)/1000.0   
  100 FORMAT(1X,I4,'-',I2,'-',I2,' UTC Time:',I2,':',I2,':',F6.3)
  WRITE(*,110)ANGLE_EOM,ANGLE_EO,ANGLE_MO
  110 FORMAT(' ANGLE_EOM =',F10.6/,' ANGLE_EO  =',F10.6/,' ANGLE_MO  =',F10.6/)

  END PROGRAM MOON_ECLIPSE
