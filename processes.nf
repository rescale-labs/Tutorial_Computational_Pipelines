#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process run_abaqus {
  label 'abaqus_job'
  errorStrategy 'finish'
  publishDir "output", mode: 'copy'

  input:
    path inputfile_template
    path node_file
    path element_file
    val cof
    val coretype_code
    val corecount

  output:
    path '*.odb', emit: odb
    path '*', emit: restartfiles

  script:
    """
    create_tag() {
      local text="\$1"
      curl -H "Authorization: Token \${RESCALE_API_KEY}" -H "Content-Type: application/json" "\${RESCALE_API_BASE_URL}/api/v2/jobs/\${RESCALE_JOB_ID}/tags/" -X POST -d "{ \\"name\\": \\"\${text}\\" }"
    }
    create_tag "Computational_Pipeline"
    runname=\$(basename "${workflow.projectDir}")
    create_tag "Study:\${runname}"
    create_tag "cof:${cof}"

    template_base=\$(basename "$inputfile_template" .inp)
    jobname="\${template_base}_${cof}"
    inputfile="\${jobname}.inp"
    cp $inputfile_template \$inputfile
    sed -i 's/<cof>/$cof/g' \$inputfile
    abaqus job=\$jobname cpus=\$RESCALE_CORES_PER_SLOT mp_mode=mpi interactive
    """

  stub:
    """
    template_base=\$(basename "$inputfile_template" .inp)
    jobname="\${template_base}_${cof}"
    echo "running abaqus"
    echo "#test" > \${jobname}.dat
    echo "#test" > \${jobname}.msg
    echo "#test" > \${jobname}.odb
    echo "#test" > \${jobname}.res
    """

}


process run_abaqus_restart {
  label 'abaqus_job'
  errorStrategy 'finish'
  publishDir "output", mode: 'copy'

  input:
    path inputfile_template
    path node_file
    path element_file
    val cof
    path restartfiles
    val coretype_code
    val corecount

  output:
    path '*.odb', emit: odb
    path '*', emit: restartfiles

  script:
    """
    create_tag() {
      local text="\$1"
      curl -H "Authorization: Token \${RESCALE_API_KEY}" -H "Content-Type: application/json" "\${RESCALE_API_BASE_URL}/api/v2/jobs/\${RESCALE_JOB_ID}/tags/" -X POST -d "{ \\"name\\": \\"\${text}\\" }"
    }
    create_tag "Computational_Pipeline"
    runname=\$(basename "${workflow.projectDir}")
    create_tag "Study:\${runname}"
    create_tag "cof:${cof}"

    template_base=\$(basename "$inputfile_template" .inp)
    jobname="\${template_base}_${cof}"
    inputfile="\${jobname}.inp"
    restartfiles_array=($restartfiles)
    first_restartfile=\${restartfiles_array[0]}
    oldjobname="\${first_restartfile%.*}"
    cp $inputfile_template \$inputfile
    sed -i 's/<cof>/$cof/g' \$inputfile
    abaqus job=\$jobname oldjob=\$oldjobname cpus=\$RESCALE_CORES_PER_SLOT mp_mode=mpi interactive
    """

  stub:
    """
    template_base=\$(basename "$inputfile_template" .inp)
    jobname="\${template_base}_${cof}"
    echo "running abaqus (restart)"
    echo "#test" > \${jobname}.dat
    echo "#test" > \${jobname}.msg
    echo "#test" > \${jobname}.odb
    echo "#test" > \${jobname}.res
    """

}


process run_abaqus_datacheck {
  label 'abaqus_datacheck'
  errorStrategy 'finish'
  publishDir "output", mode: 'copy'

  input:
    path inputfile_template
    path node_file
    path element_file
    val cof

  output:
    path '*.dat', emit: dat

  script:
    """
    create_tag() {
      local text="\$1"
      curl -H "Authorization: Token \${RESCALE_API_KEY}" -H "Content-Type: application/json" "\${RESCALE_API_BASE_URL}/api/v2/jobs/\${RESCALE_JOB_ID}/tags/" -X POST -d "{ \\"name\\": \\"\${text}\\" }"
    }
    create_tag "Computational_Pipeline"
    runname=\$(basename "${workflow.projectDir}")
    create_tag "Study:\${runname}"
    create_tag "cof:${cof}"

    template_base=\$(basename "$inputfile_template" .inp)
    jobname="\${template_base}_${cof}"
    inputfile="\${jobname}.inp"
    cp $inputfile_template \$inputfile
    sed -i 's/<cof>/$cof/g' \$inputfile
    abaqus datacheck job=\$jobname cpus=\$RESCALE_CORES_PER_SLOT mp_mode=mpi interactive
    """

  stub:
    """
    echo "running abaqus datacheck"
    cp -v /Users/bitsche/Downloads/brake_squeal_template_0.3.dat .
    """

}

process select_hardware {
  debug true
  input:
    path datfile
  output:
    env ct_code, emit: coretype_code
    env c_count, emit: corecount
  script:
    """
    suggest_hardware.py $datfile 2>&1
    ct_code=\$(cat hardware.json | jq -r '.code')
    c_count=\$(cat hardware.json | jq -r '.corecount')
    """

  stub:
    """
    ct_code=kyanite
    c_count=4
    echo "Suggestion: \${ct_code} on \${c_count} cores"
    """
}