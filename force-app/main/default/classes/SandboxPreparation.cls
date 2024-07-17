global class SandboxPreparation implements SandboxPostCopy {
 
    global void runApexClass(System.SandboxContext context) {
        SampleDataCreator.createSampleData(System.Label.Apex_sample_data_filename);
    }
}