# README

The purpose of the program is to compute the initial eclipse time of the first lunar eclipse in 2019, when the moon just entered the umbra, based on the [DE421](https://ipnpr.jpl.nasa.gov/progress_report/42-178/178C.pdf) and [SOFA](http://www.iausofa.org/index.html).


### FILE STRUCTURE

**version**

The coder wrote the main function in C language and FORTRAN language respectively. they call the same library functions but have different makefile configuration files. Please chone or download the version your need as follows:

- FORTRAN：1，3，4，5，7，8
- C：1，2，4，5，6，8


| NO.  | FILENAME         | DESCRIPTION                  |
| ---- | ---------------- | ---------------------------- |
| 1    | JPLEPH           | the binary JPL ephemeris file. |
| 2    | MOON_ECLIPSE.c   | the main function file in C language. |
| 3    | MOON_ECLIPSE.f95 | the main function file in FORTRAN language. |
| 4    | README.md        | readme file.         |
| 5    | SOFALIB.f        | SOFA subroutines used in this project. |
| 6    | makefile_C       | C version makefile (the file directs make on how to compile and link a program). |
| 7    | makefile_F       | FORTRAN version makefile (the file directs make on how to compile and link a program). |
| 8    | selcon.f         | the select constant file in the DE ephemeris. |



### RUN PROGRAM

Please check that [gfortran](https://gcc.gnu.org/fortran/) and [gcc](https://gcc.gnu.org/) are installed before running. If not, refer to ['here'](http://blog.sina.com.cn/s/blog_6dd65c6f0100y793.html) please. 

- **FORTRAN Version**

```
$ make -f makefile_F
$ ./MOON_F.exe
```

- **C Version**

```
$ make -f makefile_C
$ ./MOON_C.exe
```



### PRINCIPLES AND STRATEGIES

1. The figure below shows the spatial relationship between the earth, the moon and the sun before the eclipse,

![](https://github.com/Sardingfish/MOON_ECLIPSE/blob/master/image/orige.png)

<p align = "center">Figure 1. Schematic diagram of the spatial relationship between the earth, the moon and the sun at the time before the eclipse</p>

>>>>Where S, E and M are the sun, the earth and the moon; O is the earth's umbra cone; ∠EOM is the Angle between the vectors EO and MO; ∠OE and ∠OM are the angular radii of the earth and moon relative to the shadow cone, respectively. When an eclipse occurs, ∠EOM is equal to ∠OE plus ∠OM.



2. Since it takes time for the sun's rays to leave the sun and pass through the earth to form a shadow cone, it is necessary to calculate the light travel time. The figure below is a schematic diagram for calculating the light line.

![image](https://github.com/Sardingfish/MOON_ECLIPSE/blob/master/image/lighttime.png)

<p align = "center">Figure 2. Iteratively solve for light travel time</p>

  >>Steps as follows:

>>>>(1). Calculate the distance L0 from the sun to the earth according to the JPEPH of given time T0, then compute the light trivial time DT0.
  
>>>>(2). Calculate the new site of T0+DT0 based on the velocity of the object being measured,re-calculate the distance L1 from the sun to the earth,compute the light trivial time DT1.

>>>>(3). Calculate the new site of T0+DT1 based on the velocity of the object being measured,re-calculate the distance L2 from the sun to the earth,compute the light trivial time DT2.

>>>>(4). When the |DTn - DTn-1| approximately equal zero, We get the precise light trivial time DTn (n > = 1), and then we can calculate the measured body's location accurately.



3. Strategies used to speed up the computation process

![image](https://github.com/Sardingfish/MOON_ECLIPSE/blob/master/image/mostlikelyday.png)

<p align = "center">Figure 3. Locate the most likely day</p>

>>>>-- Since the eclipse occurs in a straight line from the date to the earth and the moon, the Angle between the sun and the earth and the moon is close to 180 degrees, the first step is to take a day as the step length, filter the time when the Angle is too large (the time when the eclipse is impossible), and locate the day when the eclipse occurs.
   
>>>>--The distance between the shadow cone and the earth is equal to about 10000 earth's radius, the moon to the earth's distance is equal to about 60 radius of the earth, When an eclipse occurs the Angle between moon-earth and earth-cone less than 1 °

>>>>-- After locating the most likely time, You can continue to approach the eclipse at smaller intervals, such as half a day.

4. The procedure flow is as follows:

   ![](https://github.com/Sardingfish/MOON_ECLIPSE/blob/master/image/FLOW2.png)

   <p align = "center">Figure 4. The flow chart</p>

   1. Read astronomical units "AU" light speed "CLIGHT" and other constants from the binary almanac file JPLEPH.
   2. Converte the Gregorian calendar to the Julian calendar.
   3. Iterate to the day when an eclipse is likely to occur
   4. Iterate over the light travel time.
   5. Calculate the vector STE from the sun to the earth.
   6. Calculate the vector ETO from the earth to the shadow cone according to the similar triangle principle.
   7. Calculate the MTE(vector from the moon to the earth).
   8. Calculate the MTO according to the vector addition rule.
   9. Calculate the Angle between vector ETO and MTO according to cosine theorem.
   10. Calculate the angular radius of the shadow cone relative to the earth and the moon according to the principle of inverse trigonometric function.
   11. Compute ERR, ERR = ∠EOM - ∠OM - ∠ OE.
   12. Judge ERR < = 0? , if yes, jump to 13; if not, time +1 then jump to 4.
   13. Converte the Julian calendar to the Gregorian calendar.
   14. Converte the decimal part to UTC time.
   15. Output the results.



5. The calculation results of the program need to be referred to. Timeanddata of stavanger, Norway gives the time of the first lunar eclipse in 2019 as shown in the figure below:

>>>>Source of the image:[https://www.timeanddate.com/eclipse/lunar/2019-january-21](https://www.timeanddate.com/eclipse/lunar/2019-january-21)

![](https://github.com/Sardingfish/MOON_ECLIPSE/blob/master/image/reference.png)

<p align = "center">Figure 5. Reference time</p>




6. The following is the result of running the program,it is in good agreement with Figure 5.

![](https://github.com/Sardingfish/MOON_ECLIPSE/blob/master/image/result.png)
<p align = "center">Figure 6. The result of the program</p>


### SUBROUTINES

The subroutines invoked by the program are listed below:

```fortran
SUBROUTINE iau_CAL2JD ( IY, IM, ID, DJM0, DJM, J )
```

1. **所在文件**：cal2jd.for
2. **功能说明**：格里高历转为儒略历
3. **参数说明**：

```
  Given:
     IY,IM,ID    i     year, month, day in Gregorian calendar (Note 1)

  Returned:
     DJM0        d     MJD zero-point: always 2400000.5
     DJM         d     Modified Julian Date for 0 hrs
     J           i     status:
                           0 = OK
                          -1 = bad year   (Note 3: JD not computed)
                          -2 = bad month  (JD not computed)
                          -3 = bad day    (JD computed)
```



```fortran
SUBROUTINE iau_JD2CAL ( DJ1, DJ2, IY, IM, ID, FD, J )
```

1. **所在文件**：jd2cal.for
2. **功能说明**：儒略历转为格里高历
3. **参数说明**：

```
  Given:
     DJ1,DJ2     d     Julian Date (Notes 1, 2)

  Returned:
     IY          i     year
     IM          i     month
     ID          i     day
     FD          d     fraction of day
     J           i     status:
                           0 = OK
                          -1 = unacceptable date (Note 1)
```



```fortran
SUBROUTINE iau_PDP ( A, B, ADB )
```

1. **所在文件**：pdp.for
2. **功能说明**：向量做点积
3. **参数说明**：

```
Given:
     A        d(3)      first p-vector
     B        d(3)      second p-vector

  Returned:
     ADB      d         A . B
```



```fortran
SUBROUTINE sla_DD2TF (NDP, DAYS, SIGN, IHMSF)
```

1. **所在文件**：selcon.f
2. **功能说明**：天到时分秒
3. **参数说明**：

```
  Given:
     NDP       int      number of decimal places of seconds
     DAYS      dp       interval in days

  Returned:
     SIGN      char     '+' or '-'
     IHMSF     int(4)   hours, minutes, seconds, fraction
```



```fortran
subroutine selconQ(nams,vals)
```

1. **所在文件**：selcon.f
2. **功能说明**：常量提取
3. **参数说明**：

```
  Input 

           nams :  names (character*6)

  Output

           vals :  values corresponding to the input names

  QI-ZHAOXIANG@20130402

```



```fortran
SUBROUTINE PLEPH ( ET, NTARG, NCENT, RRD )
```

1. **所在文件**：selcon.f
2. **功能说明**：返回给定时间中心天体到目标天体的矢量
3. **参数说明**：

```
     THIS SUBROUTINE READS THE JPL PLANETARY EPHEMERIS
     AND GIVES THE POSITION AND VELOCITY OF THE POINT 'NTARG'
     WITH RESPECT TO 'NCENT'.

     CALLING SEQUENCE PARAMETERS:

       ET = D.P. JULIAN EPHEMERIS DATE AT WHICH INTERPOLATION
            IS WANTED.

       ** NOTE THE ENTRY DPLEPH FOR A DOUBLY-DIMENSIONED TIME **
          THE REASON FOR THIS OPTION IS DISCUSSED IN THE
          SUBROUTINE STATE

     NTARG = INTEGER NUMBER OF 'TARGET' POINT.

     NCENT = INTEGER NUMBER OF CENTER POINT.

            THE NUMBERING CONVENTION FOR 'NTARG' AND 'NCENT' IS:

                1 = MERCURY           8 = NEPTUNE
                2 = VENUS             9 = PLUTO
                3 = EARTH            10 = MOON
                4 = MARS             11 = SUN
                5 = JUPITER          12 = SOLAR-SYSTEM BARYCENTER
                6 = SATURN           13 = EARTH-MOON BARYCENTER
                7 = URANUS           14 = NUTATIONS (LONGITUDE AND OBLIQ)
                            15 = LIBRATIONS, IF ON EPH FILE

             (IF NUTATIONS ARE WANTED, SET NTARG = 14. FOR LIBRATIONS,
              SET NTARG = 15. SET NCENT=0.)

      RRD = OUTPUT 6-WORD D.P. ARRAY CONTAINING POSITION AND VELOCITY
            OF POINT 'NTARG' RELATIVE TO 'NCENT'. THE UNITS ARE AU AND
            AU/DAY. FOR LIBRATIONS THE UNITS ARE RADIANS AND RADIANS
            PER DAY. IN THE CASE OF NUTATIONS THE FIRST FOUR WORDS OF
            RRD WILL BE SET TO NUTATIONS AND RATES, HAVING UNITS OF
            RADIANS AND RADIANS/DAY.

            The option is available to have the units in km and km/sec.
            For this, set km=.true. in the STCOMX common block.
```



### GET CODE

this project：[https://github.com/Sardingfish/MOON_ECLIPSE](https://github.com/Sardingfish/MOON_ECLIPSE)

SOFA：[http://www.iausofa.org/index.html](http://www.iausofa.org/index.html)

DE/LE EPHEMERIS：[ftp://ssd.jpl.nasa.gov](ftp://ssd.jpl.nasa.gov)

<p align = "right">WRITE BY Ding Junsheng</p>
<p align = "right">2018/11/24 16:46</p>


