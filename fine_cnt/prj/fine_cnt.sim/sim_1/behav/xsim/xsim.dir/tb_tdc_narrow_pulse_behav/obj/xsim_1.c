/**********************************************************************/
/*   ____  ____                                                       */
/*  /   /\/   /                                                       */
/* /___/  \  /                                                        */
/* \   \   \/                                                         */
/*  \   \        Copyright (c) 2003-2020 Xilinx, Inc.                 */
/*  /   /        All Right Reserved.                                  */
/* /---/   /\                                                         */
/* \   \  /  \                                                        */
/*  \___\/\___\                                                       */
/**********************************************************************/

#if defined(_WIN32)
 #include "stdio.h"
 #define IKI_DLLESPEC __declspec(dllimport)
#else
 #define IKI_DLLESPEC
#endif
#include "iki.h"
#include <string.h>
#include <math.h>
#ifdef __GNUC__
#include <stdlib.h>
#else
#include <malloc.h>
#define alloca _alloca
#endif
/**********************************************************************/
/*   ____  ____                                                       */
/*  /   /\/   /                                                       */
/* /___/  \  /                                                        */
/* \   \   \/                                                         */
/*  \   \        Copyright (c) 2003-2020 Xilinx, Inc.                 */
/*  /   /        All Right Reserved.                                  */
/* /---/   /\                                                         */
/* \   \  /  \                                                        */
/*  \___\/\___\                                                       */
/**********************************************************************/

#if defined(_WIN32)
 #include "stdio.h"
 #define IKI_DLLESPEC __declspec(dllimport)
#else
 #define IKI_DLLESPEC
#endif
#include "iki.h"
#include <string.h>
#include <math.h>
#ifdef __GNUC__
#include <stdlib.h>
#else
#include <malloc.h>
#define alloca _alloca
#endif
typedef void (*funcp)(char *, char *);
extern int main(int, char**);
IKI_DLLESPEC extern void execute_48(char*, char *);
IKI_DLLESPEC extern void execute_49(char*, char *);
IKI_DLLESPEC extern void execute_51(char*, char *);
IKI_DLLESPEC extern void execute_55(char*, char *);
IKI_DLLESPEC extern void execute_56(char*, char *);
IKI_DLLESPEC extern void execute_57(char*, char *);
IKI_DLLESPEC extern void execute_58(char*, char *);
IKI_DLLESPEC extern void execute_59(char*, char *);
IKI_DLLESPEC extern void execute_60(char*, char *);
IKI_DLLESPEC extern void execute_61(char*, char *);
IKI_DLLESPEC extern void execute_62(char*, char *);
IKI_DLLESPEC extern void execute_63(char*, char *);
IKI_DLLESPEC extern void execute_64(char*, char *);
IKI_DLLESPEC extern void execute_592(char*, char *);
IKI_DLLESPEC extern void execute_593(char*, char *);
IKI_DLLESPEC extern void execute_594(char*, char *);
IKI_DLLESPEC extern void execute_595(char*, char *);
IKI_DLLESPEC extern void execute_596(char*, char *);
IKI_DLLESPEC extern void execute_597(char*, char *);
IKI_DLLESPEC extern void execute_3(char*, char *);
IKI_DLLESPEC extern void execute_44(char*, char *);
IKI_DLLESPEC extern void execute_47(char*, char *);
IKI_DLLESPEC extern void execute_70(char*, char *);
IKI_DLLESPEC extern void execute_71(char*, char *);
IKI_DLLESPEC extern void vlog_const_rhs_process_execute_0_fast_no_reg_no_agg(char*, char*, char*);
IKI_DLLESPEC extern void vlog_simple_process_execute_0_fast_no_reg_no_agg(char*, char*, char*);
IKI_DLLESPEC extern void execute_434(char*, char *);
IKI_DLLESPEC extern void execute_435(char*, char *);
IKI_DLLESPEC extern void execute_436(char*, char *);
IKI_DLLESPEC extern void execute_438(char*, char *);
IKI_DLLESPEC extern void execute_439(char*, char *);
IKI_DLLESPEC extern void execute_440(char*, char *);
IKI_DLLESPEC extern void execute_442(char*, char *);
IKI_DLLESPEC extern void execute_443(char*, char *);
IKI_DLLESPEC extern void execute_444(char*, char *);
IKI_DLLESPEC extern void execute_446(char*, char *);
IKI_DLLESPEC extern void execute_447(char*, char *);
IKI_DLLESPEC extern void execute_448(char*, char *);
IKI_DLLESPEC extern void execute_450(char*, char *);
IKI_DLLESPEC extern void execute_451(char*, char *);
IKI_DLLESPEC extern void execute_452(char*, char *);
IKI_DLLESPEC extern void execute_454(char*, char *);
IKI_DLLESPEC extern void execute_455(char*, char *);
IKI_DLLESPEC extern void execute_456(char*, char *);
IKI_DLLESPEC extern void execute_458(char*, char *);
IKI_DLLESPEC extern void execute_459(char*, char *);
IKI_DLLESPEC extern void execute_460(char*, char *);
IKI_DLLESPEC extern void execute_462(char*, char *);
IKI_DLLESPEC extern void execute_463(char*, char *);
IKI_DLLESPEC extern void execute_464(char*, char *);
IKI_DLLESPEC extern void execute_466(char*, char *);
IKI_DLLESPEC extern void execute_467(char*, char *);
IKI_DLLESPEC extern void execute_468(char*, char *);
IKI_DLLESPEC extern void execute_470(char*, char *);
IKI_DLLESPEC extern void execute_471(char*, char *);
IKI_DLLESPEC extern void execute_472(char*, char *);
IKI_DLLESPEC extern void execute_474(char*, char *);
IKI_DLLESPEC extern void execute_475(char*, char *);
IKI_DLLESPEC extern void execute_476(char*, char *);
IKI_DLLESPEC extern void execute_478(char*, char *);
IKI_DLLESPEC extern void execute_479(char*, char *);
IKI_DLLESPEC extern void execute_480(char*, char *);
IKI_DLLESPEC extern void execute_482(char*, char *);
IKI_DLLESPEC extern void execute_483(char*, char *);
IKI_DLLESPEC extern void execute_484(char*, char *);
IKI_DLLESPEC extern void execute_486(char*, char *);
IKI_DLLESPEC extern void execute_487(char*, char *);
IKI_DLLESPEC extern void execute_488(char*, char *);
IKI_DLLESPEC extern void execute_490(char*, char *);
IKI_DLLESPEC extern void execute_491(char*, char *);
IKI_DLLESPEC extern void execute_492(char*, char *);
IKI_DLLESPEC extern void execute_494(char*, char *);
IKI_DLLESPEC extern void execute_495(char*, char *);
IKI_DLLESPEC extern void execute_496(char*, char *);
IKI_DLLESPEC extern void execute_498(char*, char *);
IKI_DLLESPEC extern void execute_499(char*, char *);
IKI_DLLESPEC extern void execute_500(char*, char *);
IKI_DLLESPEC extern void execute_502(char*, char *);
IKI_DLLESPEC extern void execute_503(char*, char *);
IKI_DLLESPEC extern void execute_504(char*, char *);
IKI_DLLESPEC extern void execute_506(char*, char *);
IKI_DLLESPEC extern void execute_507(char*, char *);
IKI_DLLESPEC extern void execute_508(char*, char *);
IKI_DLLESPEC extern void execute_510(char*, char *);
IKI_DLLESPEC extern void execute_511(char*, char *);
IKI_DLLESPEC extern void execute_514(char*, char *);
IKI_DLLESPEC extern void execute_515(char*, char *);
IKI_DLLESPEC extern void execute_516(char*, char *);
IKI_DLLESPEC extern void execute_518(char*, char *);
IKI_DLLESPEC extern void execute_519(char*, char *);
IKI_DLLESPEC extern void execute_520(char*, char *);
IKI_DLLESPEC extern void execute_522(char*, char *);
IKI_DLLESPEC extern void execute_523(char*, char *);
IKI_DLLESPEC extern void execute_524(char*, char *);
IKI_DLLESPEC extern void execute_526(char*, char *);
IKI_DLLESPEC extern void execute_527(char*, char *);
IKI_DLLESPEC extern void execute_528(char*, char *);
IKI_DLLESPEC extern void execute_530(char*, char *);
IKI_DLLESPEC extern void execute_531(char*, char *);
IKI_DLLESPEC extern void execute_532(char*, char *);
IKI_DLLESPEC extern void execute_534(char*, char *);
IKI_DLLESPEC extern void execute_535(char*, char *);
IKI_DLLESPEC extern void execute_536(char*, char *);
IKI_DLLESPEC extern void execute_538(char*, char *);
IKI_DLLESPEC extern void execute_539(char*, char *);
IKI_DLLESPEC extern void execute_540(char*, char *);
IKI_DLLESPEC extern void execute_542(char*, char *);
IKI_DLLESPEC extern void execute_543(char*, char *);
IKI_DLLESPEC extern void execute_544(char*, char *);
IKI_DLLESPEC extern void execute_546(char*, char *);
IKI_DLLESPEC extern void execute_547(char*, char *);
IKI_DLLESPEC extern void execute_548(char*, char *);
IKI_DLLESPEC extern void execute_550(char*, char *);
IKI_DLLESPEC extern void execute_551(char*, char *);
IKI_DLLESPEC extern void execute_552(char*, char *);
IKI_DLLESPEC extern void execute_554(char*, char *);
IKI_DLLESPEC extern void execute_555(char*, char *);
IKI_DLLESPEC extern void execute_556(char*, char *);
IKI_DLLESPEC extern void execute_558(char*, char *);
IKI_DLLESPEC extern void execute_559(char*, char *);
IKI_DLLESPEC extern void execute_560(char*, char *);
IKI_DLLESPEC extern void execute_562(char*, char *);
IKI_DLLESPEC extern void execute_563(char*, char *);
IKI_DLLESPEC extern void execute_564(char*, char *);
IKI_DLLESPEC extern void execute_566(char*, char *);
IKI_DLLESPEC extern void execute_567(char*, char *);
IKI_DLLESPEC extern void execute_568(char*, char *);
IKI_DLLESPEC extern void execute_570(char*, char *);
IKI_DLLESPEC extern void execute_571(char*, char *);
IKI_DLLESPEC extern void execute_572(char*, char *);
IKI_DLLESPEC extern void execute_574(char*, char *);
IKI_DLLESPEC extern void execute_575(char*, char *);
IKI_DLLESPEC extern void execute_576(char*, char *);
IKI_DLLESPEC extern void execute_578(char*, char *);
IKI_DLLESPEC extern void execute_579(char*, char *);
IKI_DLLESPEC extern void execute_580(char*, char *);
IKI_DLLESPEC extern void execute_582(char*, char *);
IKI_DLLESPEC extern void execute_583(char*, char *);
IKI_DLLESPEC extern void execute_584(char*, char *);
IKI_DLLESPEC extern void execute_586(char*, char *);
IKI_DLLESPEC extern void execute_587(char*, char *);
IKI_DLLESPEC extern void execute_588(char*, char *);
IKI_DLLESPEC extern void execute_590(char*, char *);
IKI_DLLESPEC extern void execute_591(char*, char *);
IKI_DLLESPEC extern void execute_72(char*, char *);
IKI_DLLESPEC extern void execute_73(char*, char *);
IKI_DLLESPEC extern void execute_74(char*, char *);
IKI_DLLESPEC extern void execute_77(char*, char *);
IKI_DLLESPEC extern void execute_78(char*, char *);
IKI_DLLESPEC extern void execute_79(char*, char *);
IKI_DLLESPEC extern void execute_80(char*, char *);
IKI_DLLESPEC extern void execute_66(char*, char *);
IKI_DLLESPEC extern void execute_67(char*, char *);
IKI_DLLESPEC extern void execute_68(char*, char *);
IKI_DLLESPEC extern void execute_69(char*, char *);
IKI_DLLESPEC extern void execute_598(char*, char *);
IKI_DLLESPEC extern void execute_599(char*, char *);
IKI_DLLESPEC extern void execute_600(char*, char *);
IKI_DLLESPEC extern void execute_601(char*, char *);
IKI_DLLESPEC extern void execute_602(char*, char *);
IKI_DLLESPEC extern void execute_603(char*, char *);
IKI_DLLESPEC extern void transaction_3(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_4(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_5(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_35(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_36(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_41(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_46(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_51(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_56(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_61(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_66(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_71(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_76(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_81(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_86(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_91(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_96(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_101(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_106(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_111(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_116(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_121(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_126(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_131(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_136(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_141(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_146(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_151(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_156(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_161(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_166(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_171(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_176(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_181(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_186(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_191(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_196(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_201(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_206(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_211(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_216(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_221(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_226(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_231(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_236(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void vlog_transfunc_eventcallback(char*, char*, unsigned, unsigned, unsigned, char *);
IKI_DLLESPEC extern void transaction_0(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_1(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_2(char*, char*, unsigned, unsigned, unsigned);
funcp funcTab[210] = {(funcp)execute_48, (funcp)execute_49, (funcp)execute_51, (funcp)execute_55, (funcp)execute_56, (funcp)execute_57, (funcp)execute_58, (funcp)execute_59, (funcp)execute_60, (funcp)execute_61, (funcp)execute_62, (funcp)execute_63, (funcp)execute_64, (funcp)execute_592, (funcp)execute_593, (funcp)execute_594, (funcp)execute_595, (funcp)execute_596, (funcp)execute_597, (funcp)execute_3, (funcp)execute_44, (funcp)execute_47, (funcp)execute_70, (funcp)execute_71, (funcp)vlog_const_rhs_process_execute_0_fast_no_reg_no_agg, (funcp)vlog_simple_process_execute_0_fast_no_reg_no_agg, (funcp)execute_434, (funcp)execute_435, (funcp)execute_436, (funcp)execute_438, (funcp)execute_439, (funcp)execute_440, (funcp)execute_442, (funcp)execute_443, (funcp)execute_444, (funcp)execute_446, (funcp)execute_447, (funcp)execute_448, (funcp)execute_450, (funcp)execute_451, (funcp)execute_452, (funcp)execute_454, (funcp)execute_455, (funcp)execute_456, (funcp)execute_458, (funcp)execute_459, (funcp)execute_460, (funcp)execute_462, (funcp)execute_463, (funcp)execute_464, (funcp)execute_466, (funcp)execute_467, (funcp)execute_468, (funcp)execute_470, (funcp)execute_471, (funcp)execute_472, (funcp)execute_474, (funcp)execute_475, (funcp)execute_476, (funcp)execute_478, (funcp)execute_479, (funcp)execute_480, (funcp)execute_482, (funcp)execute_483, (funcp)execute_484, (funcp)execute_486, (funcp)execute_487, (funcp)execute_488, (funcp)execute_490, (funcp)execute_491, (funcp)execute_492, (funcp)execute_494, (funcp)execute_495, (funcp)execute_496, (funcp)execute_498, (funcp)execute_499, (funcp)execute_500, (funcp)execute_502, (funcp)execute_503, (funcp)execute_504, (funcp)execute_506, (funcp)execute_507, (funcp)execute_508, (funcp)execute_510, (funcp)execute_511, (funcp)execute_514, (funcp)execute_515, (funcp)execute_516, (funcp)execute_518, (funcp)execute_519, (funcp)execute_520, (funcp)execute_522, (funcp)execute_523, (funcp)execute_524, (funcp)execute_526, (funcp)execute_527, (funcp)execute_528, (funcp)execute_530, (funcp)execute_531, (funcp)execute_532, (funcp)execute_534, (funcp)execute_535, (funcp)execute_536, (funcp)execute_538, (funcp)execute_539, (funcp)execute_540, (funcp)execute_542, (funcp)execute_543, (funcp)execute_544, (funcp)execute_546, (funcp)execute_547, (funcp)execute_548, (funcp)execute_550, (funcp)execute_551, (funcp)execute_552, (funcp)execute_554, (funcp)execute_555, (funcp)execute_556, (funcp)execute_558, (funcp)execute_559, (funcp)execute_560, (funcp)execute_562, (funcp)execute_563, (funcp)execute_564, (funcp)execute_566, (funcp)execute_567, (funcp)execute_568, (funcp)execute_570, (funcp)execute_571, (funcp)execute_572, (funcp)execute_574, (funcp)execute_575, (funcp)execute_576, (funcp)execute_578, (funcp)execute_579, (funcp)execute_580, (funcp)execute_582, (funcp)execute_583, (funcp)execute_584, (funcp)execute_586, (funcp)execute_587, (funcp)execute_588, (funcp)execute_590, (funcp)execute_591, (funcp)execute_72, (funcp)execute_73, (funcp)execute_74, (funcp)execute_77, (funcp)execute_78, (funcp)execute_79, (funcp)execute_80, (funcp)execute_66, (funcp)execute_67, (funcp)execute_68, (funcp)execute_69, (funcp)execute_598, (funcp)execute_599, (funcp)execute_600, (funcp)execute_601, (funcp)execute_602, (funcp)execute_603, (funcp)transaction_3, (funcp)transaction_4, (funcp)transaction_5, (funcp)transaction_35, (funcp)transaction_36, (funcp)transaction_41, (funcp)transaction_46, (funcp)transaction_51, (funcp)transaction_56, (funcp)transaction_61, (funcp)transaction_66, (funcp)transaction_71, (funcp)transaction_76, (funcp)transaction_81, (funcp)transaction_86, (funcp)transaction_91, (funcp)transaction_96, (funcp)transaction_101, (funcp)transaction_106, (funcp)transaction_111, (funcp)transaction_116, (funcp)transaction_121, (funcp)transaction_126, (funcp)transaction_131, (funcp)transaction_136, (funcp)transaction_141, (funcp)transaction_146, (funcp)transaction_151, (funcp)transaction_156, (funcp)transaction_161, (funcp)transaction_166, (funcp)transaction_171, (funcp)transaction_176, (funcp)transaction_181, (funcp)transaction_186, (funcp)transaction_191, (funcp)transaction_196, (funcp)transaction_201, (funcp)transaction_206, (funcp)transaction_211, (funcp)transaction_216, (funcp)transaction_221, (funcp)transaction_226, (funcp)transaction_231, (funcp)transaction_236, (funcp)vlog_transfunc_eventcallback, (funcp)transaction_0, (funcp)transaction_1, (funcp)transaction_2};
const int NumRelocateId= 210;

void relocate(char *dp)
{
	iki_relocate(dp, "xsim.dir/tb_tdc_narrow_pulse_behav/xsim.reloc",  (void **)funcTab, 210);

	/*Populate the transaction function pointer field in the whole net structure */
}

void sensitize(char *dp)
{
	iki_sensitize(dp, "xsim.dir/tb_tdc_narrow_pulse_behav/xsim.reloc");
}

	// Initialize Verilog nets in mixed simulation, for the cases when the value at time 0 should be propagated from the mixed language Vhdl net

void wrapper_func_0(char *dp)

{

}

void simulate(char *dp)
{
		iki_schedule_processes_at_time_zero(dp, "xsim.dir/tb_tdc_narrow_pulse_behav/xsim.reloc");
	wrapper_func_0(dp);

	iki_execute_processes();

	// Schedule resolution functions for the multiply driven Verilog nets that have strength
	// Schedule transaction functions for the singly driven Verilog nets that have strength

}
#include "iki_bridge.h"
void relocate(char *);

void sensitize(char *);

void simulate(char *);

extern SYSTEMCLIB_IMP_DLLSPEC void local_register_implicit_channel(int, char*);
extern SYSTEMCLIB_IMP_DLLSPEC int xsim_argc_copy ;
extern SYSTEMCLIB_IMP_DLLSPEC char** xsim_argv_copy ;

int main(int argc, char **argv)
{
    iki_heap_initialize("ms", "isimmm", 0, 2147483648) ;
    iki_set_sv_type_file_path_name("xsim.dir/tb_tdc_narrow_pulse_behav/xsim.svtype");
    iki_set_crvs_dump_file_path_name("xsim.dir/tb_tdc_narrow_pulse_behav/xsim.crvsdump");
    void* design_handle = iki_create_design("xsim.dir/tb_tdc_narrow_pulse_behav/xsim.mem", (void *)relocate, (void *)sensitize, (void *)simulate, (void*)0, 0, isimBridge_getWdbWriter(), 0, argc, argv);
     iki_set_rc_trial_count(100);
    (void) design_handle;
    return iki_simulate_design();
}
