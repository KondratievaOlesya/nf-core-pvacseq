//
// MODULE: Download MHC Class I data
//
process DOWNLOAD_MHC_I {
    input:
    path pvacseq_iedb_dir

    output:
    path "$pvacseq_iedb_dir/mhc_i", emit: iedb_mhc_i

    script:
    """
    wget https://downloads.iedb.org/tools/mhci/3.1.5/IEDB_MHC_I-3.1.5.tar.gz
    tar -zxvf IEDB_MHC_I-3.1.5.tar.gz
    mv mhc_i $pvacseq_iedb_dir/mhc_i
    rm -rf IEDB_MHC_I-3.1.5.tar.gz
    """
}

//
// MODULE: Download MHC Class II data
//
process DOWNLOAD_MHC_II {
    input:
    path pvacseq_iedb_dir

    output:
    path "$pvacseq_iedb_dir/mhc_ii", emit: iedb_mhc_ii

    script:
    """
    wget https://downloads.iedb.org/tools/mhcii/3.1.11/IEDB_MHC_II-3.1.11.tar.gz
    tar -zxvf IEDB_MHC_II-3.1.11.tar.gz
    mv mhc_ii $pvacseq_iedb_dir/mhc_ii
    rm -rf IEDB_MHC_II-3.1.11.tar.gz
    """
}


//
// Workflow: Configure pVACseq tools
//
workflow CONFIGURE_PVACSEQ_IEDB {
    take:
    pvacseq_iedb_dir         // directory with IEDB for pVACseq
    pvacseq_algorithm        // string: algorithms for pVACseq 

    main:

    def valid_mhc_i_algorithms = [
        'BigMHC_EL', 'BigMHC_IM', 'DeepImmuno', 'MHCflurry', 'MHCflurryEL',
        'MHCnuggetsI', 'NNalign', 'NetMHC', 'NetMHCpan', 'NetMHCpanEL',
        'PickPocket', 'SMM', 'SMMPMBEC', 'SMMalign', 'all', 'all_class_i'
    ]

    def valid_mhc_ii_algorithms = [
        'MHCnuggetsII', 'NetMHCIIpan', 'NetMHCIIpanEL', 'NetMHCcons',
        'all', 'all_class_ii'
    ]

    def requires_mhc_i = false
    def requires_mhc_ii = false

    // Determine which MHC classes are required
    pvacseq_algorithm.split(' ').each { algorithm ->
        if (valid_mhc_i_algorithms.contains(algorithm)) {
            requires_mhc_i = true
        }
        if (valid_mhc_ii_algorithms.contains(algorithm)) {
            requires_mhc_ii = true
        }
    }

    // If we dont have any requirements, the algorithm string is wrong
    if (!requires_mhc_i && !requires_mhc_ii) {
        throw new IllegalArgumentException("Invalid algorithm string: '${pvacseq_algorithm}'. It must match at least one valid MHC class I or II algorithm.")
    }

    // Create iedb directory if needed
    if (!(pvacseq_iedb_dir && file(pvacseq_iedb_dir).exists())) {
        iedb_dir = file("$params.outdir/iedb")
        iedb_dir.mkdir()
    } else {
        iedb_dir = file("$pvacseq_iedb_dir")
    }
    println "IEDB folder will be $iedb_dir"

    // Paths for MHC I and MHC II
    def mhc_i_path = params.NO_FILE
    def mhc_ii_path = params.NO_FILE

    // Add existing paths or download MHC I
    if (requires_mhc_i) {
        if (file("$iedb_dir/mhc_i").exists()) {
            println "MHC Class I directory exists at $iedb_dir/mhc_i"
            mhc_i_path = file("$iedb_dir/mhc_i")
        } else {
            println "MHC Class I is required but does not exist. Downloading..."
            DOWNLOAD_MHC_I(iedb_dir)
            mhc_i_path = DOWNLOAD_MHC_I.out.iedb_mhc_i
        }
    }

    // Add existing paths or download MHC II
    if (requires_mhc_ii) {
        if (file("$iedb_dir/mhc_ii").exists()) {
            println "MHC Class II directory exists at $iedb_dir/mhc_ii"
            mhc_ii_path = file("$iedb_dir/mhc_ii")
        } else {
            println "MHC Class II is required but does not exist. Downloading..."
            DOWNLOAD_MHC_II(iedb_dir)
            mhc_ii_path = DOWNLOAD_MHC_II.out.iedb_mhc_ii
        }
    }
    // Emit the paths
    emit:
    iedb_dir = iedb_dir
    iedb_mhc_i = mhc_i_path
    iedb_mhc_ii = mhc_ii_path
}
