mkdir -p package
pip install --target ./package -r requirements.txt
cd package
zip -r ../my_deployment_package.zip .
zip my_deployment_package.zip ../src/lambda_function.py
