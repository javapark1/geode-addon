REM Set the following environment variables to reflect your environment.
REM Note that the uer name must be your Windows user name.
set USERNAME=dpark

REM Minikube IP can be obtained by running 'minikube ip' or 'minikube.exe ip'.
set MINIKUBE_IP=172.17.34.252

REM Change the port number only if you changed the default Minikube port number.
set MINIKUBE_PORT=8443

kubectl config set-cluster minikube --server=https://%MINIKUBE_IP%:%MINIKUBE_PORT% --certificate-authority=c:\Users\%USERNAME%\.minikube\ca.crt
kubectl config set-credentials minikube --client-certificate=c:\Users\%USERNAME%\.minikube\client.crt --client-key=c:\Users\%USERNAME%\.minikube\client.key
kubectl config set-context minikube --cluster=minikube --user=minikube
kubectl config view
kubectl config use-context minikube
kubectl get nodes
