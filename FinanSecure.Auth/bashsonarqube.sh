# 1. Limpiamos cualquier rastro anterior
rm -rf .sonarqube

# 2. Iniciamos el escaneo (Sustituye 'sqa_xxx...' por tu token)
dotnet-sonarscanner begin /k:"FinanSecure-Auth" \
  /d:sonar.host.url="http://localhost:9000" \
  /d:sonar.token="sqa_ab71deba5249e21b54bfa89dfb71da398c8b4cae"

# 3. Compilamos
dotnet build

# 4. Finalizamos y subimos resultados
dotnet-sonarscanner end /d:sonar.token="sqa_ab71deba5249e21b54bfa89dfb71da398c8b4cae"
