#### README

THIS IS A READ ME OF PROGRAM MOON_ECLIPSE



##### mainfiles

1. MOON_ECLIPSE.f95              !主函数文件
2. README.md                     !说明文件
3. SOFALIB.f                     !SOFA及其它官方提供的子程序集
4. JPLEPH                        !二进制历表文件
5. selcon.f                      !DE历表测试文件



##### principles and strategies

1. 下图为月食发生前时刻地月日空间关系，

![](https://github.com/Sardingfish/MOON_ECLIPSE/blob/master/picture/orig.png)

<center>Figure 1. 月食发生前时刻地月日空间关系示意图</center>

Figure 1. 中，S为太阳，E为地球，M为月球，O为地球本影影锥。初亏时刻，存在矢量OE和OM的夹角∠MOE等于视差角ω1和视差角ω2之和（视O为stars，E和M为公转轨道）。



2. 由于太阳光从太阳出发到经过地球形成影锥需要一定时间，故需要计算光行时。下图为计算光行时的示意图。

![image](https://github.com/Sardingfish/MOON_ECLIPSE/blob/master/picture/lighttime.png)

<center>Figure 2. 迭代求解光行时</center>

步骤为：

1. 从给定T0时刻的历表⼏何位置，计算观测者⾄被测体的距离L0，估算光⾏时DT0；
2. 基于被测天体运动速度计算T0+DT0时刻新位置，重新计算观测者⾄被测体的距离L1，估算光⾏时DT1；
3. 基于被测天体运动速度计算T0+DT1时刻新位置，重新计算观测者⾄被测体的距离L2，估算光⾏时DT2；
4. 当 | DTn - DTn-1 | 近似等于0时, 即计算出了精准的光⾏时DTn（n>=1）,进⽽可计算出被测体准确视位置。



3. 加快计算过程采用的策略

   -- 由于月食发生时日-地-月成一条直线，此时日-地-月所成夹角靠近180度，故首先以一天为步长，

   过滤夹角角度过大的时间，定位出月食发生的那一天。

   -- 可根据影锥大致角度，继续以半天或一小时为步长逼近，程序仅使用到半天，可根据需要缩小。



4. 程序计算结果需要有参考，挪威斯塔万格的Tmeanddate公司给出的2019年第一次月食发生时间如下图：

![](https://github.com/Sardingfish/MOON_ECLIPSE/blob/master/picture/reference.png)

<center>Figure 3. 月食参考时间</center>

图片来源：[https://www.timeanddate.com/eclipse/lunar/2019-january-21](https://www.timeanddate.com/eclipse/lunar/2019-january-21)



5. 程序运行结果如下，与Figure 3. 符合程度较佳

![](https://github.com/Sardingfish/MOON_ECLIPSE/blob/master/picture/result.png)



##### subroutines

以下列出了程序调用的子程序：

```fortran
SUBROUTINE iau_CAL2JD ( IY, IM, ID, DJM0, DJM, J )
```

1. **所在文件**：cal2jd.for
2. **功能说明**：格里高历转为儒略历
3. **参数说明**：

```
*  Given:
*     IY,IM,ID    i     year, month, day in Gregorian calendar (Note 1)
*
*  Returned:
*     DJM0        d     MJD zero-point: always 2400000.5
*     DJM         d     Modified Julian Date for 0 hrs
*     J           i     status:
*                           0 = OK
*                          -1 = bad year   (Note 3: JD not computed)
*                          -2 = bad month  (JD not computed)
*                          -3 = bad day    (JD computed)
```



```fortran
SUBROUTINE iau_JD2CAL ( DJ1, DJ2, IY, IM, ID, FD, J )
```

1. **所在文件**：jd2cal.for
2. **功能说明**：儒略历转为格里高历
3. **参数说明**：

```
*  Given:
*     DJ1,DJ2     d     Julian Date (Notes 1, 2)
*
*  Returned:
*     IY          i     year
*     IM          i     month
*     ID          i     day
*     FD          d     fraction of day
*     J           i     status:
*                           0 = OK
*                          -1 = unacceptable date (Note 1)
```



```fortran
SUBROUTINE iau_PDP ( A, B, ADB )
```

1. **所在文件**：pdp.for
2. **功能说明**：向量做点积
3. **参数说明**：

```
Given:
*     A        d(3)      first p-vector
*     B        d(3)      second p-vector
*
*  Returned:
*     ADB      d         A . B
```



```fortran
SUBROUTINE sla_DD2TF (NDP, DAYS, SIGN, IHMSF)
```

1. **所在文件**：selcon.f
2. **功能说明**：天到时分秒
3. **参数说明**：

```
*  Given:
*     NDP       int      number of decimal places of seconds
*     DAYS      dp       interval in days
*
*  Returned:
*     SIGN      char     '+' or '-'
*     IHMSF     int(4)   hours, minutes, seconds, fraction
```



```fortran
subroutine selconQ(nams,vals)
```

1. **所在文件**：selcon.f
2. **功能说明**：常量提取
3. **参数说明**：

```
c  Input 

c           nams :  names (character*6)

c  Output

c           vals :  values corresponding to the input names
C
C   QI-ZHAOXIANG@20130402

```



```fortran
SUBROUTINE PLEPH ( ET, NTARG, NCENT, RRD )
```

1. **所在文件**：selcon.f
2. **功能说明**：返回给定时间中心天体到目标天体的矢量
3. **参数说明**：

```
C     THIS SUBROUTINE READS THE JPL PLANETARY EPHEMERIS
C     AND GIVES THE POSITION AND VELOCITY OF THE POINT 'NTARG'
C     WITH RESPECT TO 'NCENT'.
C
C     CALLING SEQUENCE PARAMETERS:
C
C       ET = D.P. JULIAN EPHEMERIS DATE AT WHICH INTERPOLATION
C            IS WANTED.
C
C       ** NOTE THE ENTRY DPLEPH FOR A DOUBLY-DIMENSIONED TIME **
C          THE REASON FOR THIS OPTION IS DISCUSSED IN THE
C          SUBROUTINE STATE
C
C     NTARG = INTEGER NUMBER OF 'TARGET' POINT.
C
C     NCENT = INTEGER NUMBER OF CENTER POINT.
C
C            THE NUMBERING CONVENTION FOR 'NTARG' AND 'NCENT' IS:
C
C                1 = MERCURY           8 = NEPTUNE
C                2 = VENUS             9 = PLUTO
C                3 = EARTH            10 = MOON
C                4 = MARS             11 = SUN
C                5 = JUPITER          12 = SOLAR-SYSTEM BARYCENTER
C                6 = SATURN           13 = EARTH-MOON BARYCENTER
C                7 = URANUS           14 = NUTATIONS (LONGITUDE AND OBLIQ)
C                            15 = LIBRATIONS, IF ON EPH FILE
C
C             (IF NUTATIONS ARE WANTED, SET NTARG = 14. FOR LIBRATIONS,
C              SET NTARG = 15. SET NCENT=0.)
C
C      RRD = OUTPUT 6-WORD D.P. ARRAY CONTAINING POSITION AND VELOCITY
C            OF POINT 'NTARG' RELATIVE TO 'NCENT'. THE UNITS ARE AU AND
C            AU/DAY. FOR LIBRATIONS THE UNITS ARE RADIANS AND RADIANS
C            PER DAY. IN THE CASE OF NUTATIONS THE FIRST FOUR WORDS OF
C            RRD WILL BE SET TO NUTATIONS AND RATES, HAVING UNITS OF
C            RADIANS AND RADIANS/DAY.
C
C            The option is available to have the units in km and km/sec.
C            For this, set km=.true. in the STCOMX common block.
```



##### getcode

this project：

SOFA：[http://www.iausofa.org/index.html](http://www.iausofa.org/index.html)

DE/LE EPHEMERIS：[ftp://ssd.jpl.nasa.gov](ftp://ssd.jpl.nasa.gov)

