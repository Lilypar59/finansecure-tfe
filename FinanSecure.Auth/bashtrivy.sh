# 1. Descargar el paquete .deb oficial (Versión estable más reciente)
wget https://github.com/aquasecurity/trivy/releases/download/v0.49.1/trivy_0.49.1_Linux-64bit.deb

# 2. Instalar el paquete usando dpkg
sudo dpkg -i trivy_0.49.1_Linux-64bit.deb

# 3. Verificar la instalación
trivy --version
