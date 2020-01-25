#!/bin/bash

install_zip_dependencies(){
# 	echo "Installing and zipping dependencies..."
# 	mkdir python
# 	pip install --target=python -r requirements.txt
# 	zip -r dependencies.zip ./python
	poetry export -f requirements.txt -o requirements.txt && \
        pip install -r requirements.txt --target python && \
        rm requirements.txt && zip -r ./python.zip python/ && \
	zip python.zip -d docker* Docker* .\*
#         rm -rf python
}

publish_dependencies_as_layer(){
	echo "Publishing dependencies as a layer..."
	local result=$(aws lambda publish-layer-version --region "${AWS_DEFAULT_REGION}" --layer-name "${LAMBDA_LAYER_ARN}" --zip-file fileb://python.zip)
	LAYER_VERSION=$(jq '.Version' <<< "$result")
	rm -rf python
# 	rm dependencies.zip
}

publish_function_code(){
	echo "Deploying the code itself..."
	zip -r financial-api.zip . -x \*.git\* && \
	zip financial-api.zip -d docker* Docker* .\*
	aws lambda update-function-code --region "${AWS_DEFAULT_REGION}" --function-name "${LAMBDA_FUNCTION_NAME}" --zip-file fileb://financial-api.zip
}

update_function_layers(){
	echo "Using the layer in the function..."
	aws lambda update-function-configuration --region "${AWS_DEFAULT_REGION}" --function-name "${LAMBDA_FUNCTION_NAME}" --layers "${LAMBDA_LAYER_ARN}:${LAYER_VERSION}"
}

deploy_lambda_function(){
	[ -d "backend" ] && cd backend
	
	install_zip_dependencies
	publish_dependencies_as_layer
	publish_function_code
	update_function_layers
}

deploy_lambda_function
echo "Done."
