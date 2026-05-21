function aws-login --description "Morning AWS SSO login - authenticates all profiles via aws-sso"
    set -l sso_session "aws-sso"
    set -l sso_url "https://datasutram.awsapps.com/start/"

    echo "Logging into AWS SSO ($sso_session)..."
    echo "URL: $sso_url"
    echo ""

    aws sso login --sso-session $sso_session

    if test $status -eq 0
        echo ""
        echo "All profiles authenticated. Token valid for ~8 hours."
        echo ""
        echo "Switch profiles with:  assume <profile>"
        echo "Fuzzy pick with:       assume"
        echo ""
        echo "Available profiles:"
        aws configure list-profiles 2>/dev/null | sort | while read -l profile
            echo "  $profile"
        end
    else
        echo ""
        echo "Login failed. Run 'granted doctor' to diagnose."
        return 1
    end
end
