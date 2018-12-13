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

![](https://github.com/Sardingfish/MOON_ECLIPSE/blob/master/image/orig.png)

<p align = "center">Figure 1. Schematic diagram of the spatial relationship between the earth, the moon and the sun at the time before the eclipse</p>

In the Figure 1, S is the sun, E is the earth, M is the moon, and O is the earth's umbra cone. At the beginning of the deficit, there is an Angle between the vector OE and OM, Angle MOE, which is equal to the sum of the Angle oh-1, the earth's relative shadow cone, and oh2, the moon's relative shadow cone.



2. Since it takes time for the sun's rays to leave the sun and pass through the earth to form a shadow cone, it is necessary to calculate the light travel time. The figure below is a schematic diagram for calculating the light line.

![image](https://github.com/Sardingfish/MOON_ECLIPSE/blob/master/image/lighttime.png)

<p align = "center">Figure 2. Iteratively solve for light travel time</p>

Steps as follows:

(1). 从给定T0时刻的历表⼏何位置，计算观测者⾄被测体的距离L0，估算光⾏时DT0；

(2). 基于被测天体运动速度计算T0+DT0时刻新位置，重新计算观测者⾄被测体的距离L1，估算光⾏时DT1；

(3). 基于被测天体运动速度计算T0+DT1时刻新位置，重新计算观测者⾄被测体的距离L2，估算光⾏时DT2；

(4). 当 | DTn - DTn-1 | 近似等于0时, 即计算出了精准的光⾏时DTn（n>=1）,进⽽可计算出被测体准确视位置。



3. Strategies used to speed up the computation process

![image](https://github.com/Sardingfish/MOON_ECLIPSE/blob/master/image/mostlikelyday.png)

<p align = "center">Figure 3. Locate the most likely day</p>

   -- 由于月食发生时日-地-月成一条直线，此时日-地-月所成夹角靠近180度，故首先以一天为步长，

   过滤夹角角度过大的时间，定位出月食发生的那一天。

   -- 可根据影锥大致角度，继续以半天或一小时为步长逼近，程序仅使用到半天，可根据需要缩小。

4. The procedure flow is as follows:

   ![](https://github.com/Sardingfish/MOON_ECLIPSE/blob/master/image/FLOW2.png)

   <p align = "center">Figure 4. The flow chart</p>

   1. 从二进制历表文件JPLEPH中读取天文单位“AU”光速“CLIGHT”等常量。
   2. 格里高利转为儒略历。
   3. 迭代定位到可能发生月食的那一天
   4. 迭代计算光行时。
   5. 计算太阳到地球的矢量STE。
   6. 相似三角形原理计算地球到影锥的矢量ETO。
   7. 计算月球到地球的矢量MTE。
   8. 矢量相加计算月球到影锥的矢量MTO。
   9. 余弦定理计算矢量ETO和MTO的夹角。
   10. 反三角函数计算影锥相对于地球和月球的视差角。
   11. 计算（地心-影锥-月球夹角）-（地球相对影锥的角半径）-（月球相对影锥的角半径）角度差值ERR。
   12. 判断ERR<=0?,若是，跳到13，若否，时间+1秒跳到4。
   13. 儒略历转为格里高利。
   14. 小数部分转为UTC。
   15. 输出结果。



5. The calculation results of the program need to be referred to. Timeanddata of stavanger, Norway gives the time of the first lunar eclipse in 2019 as shown in the figure below:

Source of the image:[https://www.timeanddate.com/eclipse/lunar/2019-january-21](https://www.timeanddate.com/eclipse/lunar/2019-january-21)

![](https://github.com/Sardingfish/MOON_ECLIPSE/blob/master/image/reference.png)

<p align = "center">Figure 5. Reference time</p>




6. The following is the result of running the program,it is in good agreement with Figure 5.

![](https://github.com/Sardingfish/MOON_ECLIPSE/blob/master/image/result.png)
<p align = "center">Figure 6. The program run result</p>


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


