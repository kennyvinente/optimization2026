import urllib.request
import re
import os

url = "https://plato.asu.edu/ftp/ampl-nlp-source/"
print(f"Buscando {url}...")
response = urllib.request.urlopen(url)
html = response.read().decode('utf-8')

mod_files = set(re.findall(r'href="([^"]+\.mod)"', html))
print(f"Encontrados {len(mod_files)} arquivos .mod")

os.makedirs("ampl_models", exist_ok=True)

for i, f in enumerate(list(mod_files)[:47]):  # Download only first 47 for now to match exactly 47 if it's longer
    file_url = url + f
    save_path = os.path.join("ampl_models", f)
    if not os.path.exists(save_path):
        print(f"Baixando {i+1}/47: {f}...")
        try:
            urllib.request.urlretrieve(file_url, save_path)
        except Exception as e:
            print(f"Erro ao baixar {f}: {e}")
    else:
        print(f"{f} já baixado.")
