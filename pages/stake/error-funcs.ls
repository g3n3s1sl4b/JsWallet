export get-error-message = (err, result)->
    return null if not (err? or result?error) 
    console.log "result?error" result?error
    err-message = 
        | result?error? => 
            error = result.description
            if error.index-of("Failed to fetch") then
                topic = (error.split(":").0 ? "")
                firstLetter = topic.substr(0, 1)
                topic = firstLetter.toUpperCase() + topic.substr(1);
                topic + ".\n Please check your internet connection and try again."
            else
                error
        | err.toString().index-of("Insufficient funds for fee") > -1 =>
            "Not enough VLX Native balance to execute this operation."
        |err? => 
            error = err.toString!
            if error.index-of("Failed to fetch") then
                topic = error
                topic + ".\n Please check your internet connection and try again."    
        | _ => "Error occured"
    return err-message