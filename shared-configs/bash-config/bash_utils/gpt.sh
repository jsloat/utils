#!/bin/bash

# Caveats
#   1. Obviously it's risky to let ChatGPT run arbitrary CLI commands on your machine, so always review before running & use caution.
#   2. $OPENAI_API_KEY will need to be exported from somewhere else, or replaced inline here, with your personal gpt token
#   3. This is just a silly POC; lots of improvements could be made (e.g. the user clarification loop won't actually continue the existing conversation)

_fetch_gpt_response() {
    local prompt="$1"
    local response

    response=$(curl -s -X POST https://api.openai.com/v1/chat/completions \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "Content-Type: application/json" \
        -d '{
      "model": "gpt-4",
      "messages": [{"role": "user", "content": "'"$prompt"'"}]
    }')

    echo "$response" | jq -r '.choices[0].message.content'
}

_get_jeeves_response() {
    local prompt="$1"
    local full_prompt="Generate a Bash script for Mac based on the following description: $prompt\nRespond only with valid bash code that can be immediately executed. Do not wrap your response in backticks or include any markdown formatting. Only return valid bash code."
    _fetch_gpt_response "$full_prompt"
}
jeeves() {
    local user_input="$1"
    local generated_code

    while true; do
        if [ -z "$user_input" ]; then
            read -r -p "Describe what you want to do in Bash: " user_input
        fi

        generated_code=$(_get_jeeves_response "$user_input")

        echo "Generated Bash code:"
        echo "$generated_code"

        read -r -p "Press Enter to run the code, or provide clarification: " clarification

        if [ -z "$clarification" ]; then
            echo "Running the generated code..."
            eval "$generated_code"
            break
        else
            user_input="$clarification"
        fi
    done
}

gpt() {
    local prompt="$1"
    _fetch_gpt_response "$prompt"
}
