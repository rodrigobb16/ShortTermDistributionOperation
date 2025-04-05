function StdoLoadStudyFile(studyfile::String)
    # Load the study file
    if !isfile(studyfile)
        error("Study file not found: $studyfile")
    end

    # Read the study file
    study = read(studyfile, String)

    # Parse the study file
    study = parse_study_file(study)

    return study
end