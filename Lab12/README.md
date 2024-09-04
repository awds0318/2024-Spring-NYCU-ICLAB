## Some Notice & Reference

TA forgot to link some file, we first need to relink the relative file (`filelist.f` & `PATTERN.v` & `TESTBED.v`)

[APR](https://timsnote.wordpress.com/digital-ic-design/ic-compiler/)

Don't forget to change the content in LEF file:

`Memory.lef`: 

`ME1 -> metal1`  `ME2 -> metal2` ... and so on
            
`VI1 -> via`     `VI2 -> via2`   ... and so on

`core -> core_5040`

## (Automatic Placement & Route) APR's procedure

**1. Data Preparation**

> According to the content in `CHIP.io` to add pad set in `CHIP_SHELL.v`. and then `./00_combine`.

Invoke innovus

**2. Reading Cell library information and Netlist for APR**

```bash
source ./my_command/run_apr.cmd
```

**3. Specify Chip Floorplan**

```bash
floorPlan -site core_5040 -r 1 0.88 250 250 250 250
```
> `1` is the Ratio(H/W), `0.88` is the Core Utillization

and then manually place the SRAM marco in Core.

**4. Connect / Define Global Net**

**5. Power Planning (Add Core Power Rings)**

**6. Power Planning (Add Block Rings)**

**7. Connect Core Power Pin**

**8. Power Planning (Add Stripes)**

**9. Connect Standard Cell Power Line**

**10. Verify DRC and LVS**

> For process 3 to 10's DRC, run:

```bash
source ./my_command/process_3to10.cmd
```

After Verify DRC, it should like:

<div align=center>
<img src=image/DRC.png>
</div>

Verify LVS:

```bash
set_verify_drc_mode -area {0 0 0 0}
verifyConnectivity -net {GND VCC} -type special -error 1000 -warning 50
```
> Manually fixing the error, and running LVS again. After fixing all error, it should like:

<div align=center>
<img src=image/LVS.png>
</div>

**11. Place Standard Cells**

**12. In-Place Optimization (IPO) - Before CTS**

```bash
source ./my_command/process_11to12.cmd
```

> It should like:

<div align=center>
<img src=image/preCTS.png>
</div>

**13. Clock Tree Synthesis (CTS)**

**14. In-Place Optimization (IPO) - After CTS**

```bash
source ./my_command/process_13to14.cmd
```

> It should like (All DRVS should be 0 & setup and hold violating paths is 0):

<div align=center>
<img src=image/postCTS.png>
</div>

**15. Add PAD Filler**

```bash
source ./my_command/addIOFiller.cmd
```

**16. SI-Prevention Detail Route (NanoRoute)**

> I have changed the EndIteration to 100 (default is 1): setNanoRouteMode -quiet -drouteEndIteration 100

```bash
source ./my_command/nanoRoute.cmd
```

LVS:

```bash
verifyConnectivity -type all -error 1000 -warning 50
```

If there is error in LVS, `shift + t` to cancel the error

DRC:

```bash
source ./my_command/postRouteDRC.cmd
```

If there is error in DRC, manually remove the metal that caused the violation.

**17. In-Place Optimization (consider crosstalk effects) - After NanoRoute**

```bash
source ./my_command/postRouteIPO.cmd
```

If the timing slack is `negative`, or there are DRVs, perform post-Route IPO in `ECO -> Optimize Design` for Hold and Setup.

After performing `ECO Optimize Design`, if the slack is still negative, congratulation... `reduce the utilization` or `increase the cycle time` and then `run all the procedure again`.

> The file in 05_APR:

<div align=center>
<img src=image/directory.png>
</div>

> It should like (All DRVS should be 0 & setup and hold violating paths is 0):

<div align=center>
<img src=image/postRoute_setup.png>
</div>

<div align=center>
<img src=image/postRoute_hold.png>
</div>

**18. Timing Analysis (Signoff) - Optional**

```bash
source ./my_command/signOff.cmd
```

**19. Add CORE Filler Cells (Just select the filler without C)**

**20. Stream Out and Write Netlist**

```bash
source ./my_command/streamOut.cmd
```

## How to pass this Lab?

> like I mention in **17. In-Place Optimization (consider crosstalk effects) - After NanoRoute**

<div align=center>
<img src=image/pass.png>
</div>

## Memory file name

> Should follow this naming rule...

`xxx_WC.db` `xxx.v` `xxx_WC.lib` `xxx_BC.lib` `xxx.lef`