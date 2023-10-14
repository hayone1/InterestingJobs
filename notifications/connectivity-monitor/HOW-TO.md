curl -s -o - https://example.com/path/to/configmap.yaml | yq eval 'select(.metadata.name == "your-configmap-name") | .data.key-to-edit = "new-value"' - | kubectl apply -f -


curl https://raw.githubusercontent.com/eirslett/frontend-maven-plugin/master/README.md > README.md
