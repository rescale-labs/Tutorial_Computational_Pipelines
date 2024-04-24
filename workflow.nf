#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { run_abaqus_datacheck } from "./processes.nf"
include { select_hardware } from "./processes.nf"
include { run_abaqus as abaqus_1 } from "./processes.nf"
include { run_abaqus_restart as abaqus_restart_1 } from "./processes.nf"
include { run_abaqus_restart as abaqus_restart_2 } from "./processes.nf"
include { run_abaqus_restart as abaqus_restart_3 } from "./processes.nf"

workflow {

  bs_template=file('brake_squeal_template.inp')
  bs_node=file('brake_squeal_node.inp')
  bs_elem=file('brake_squeal_elem.inp')
  bs_res_template = file('brake_squeal_res_template.inp')

  run_abaqus_datacheck(bs_template, bs_node, bs_elem, 0.3)
  select_hardware(run_abaqus_datacheck.out.dat)
  abaqus_1(bs_template, bs_node, bs_elem, 0.3, select_hardware.out.coretype_code, select_hardware.out.corecount)
  abaqus_restart_1(bs_res_template, bs_node, bs_elem, 0.35, abaqus_1.out.restartfiles.collect(), select_hardware.out.coretype_code, select_hardware.out.corecount)
  abaqus_restart_2(bs_res_template, bs_node, bs_elem, 0.4, abaqus_1.out.restartfiles.collect(), select_hardware.out.coretype_code, select_hardware.out.corecount)
  abaqus_restart_3(bs_res_template, bs_node, bs_elem, 0.45, abaqus_1.out.restartfiles.collect(), select_hardware.out.coretype_code, select_hardware.out.corecount)

}



