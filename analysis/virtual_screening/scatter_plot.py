import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# Opcional: usar el estilo de seaborn para que se vea más profesional
sns.set_theme(style="whitegrid")

hongo_csv = "/home/Mayday3003/Documents/universidad/biologia/Proyecto2/analysis/virtual_screening/screening/resultados_1000/scores_hongo.csv"
humana_csv = "/home/Mayday3003/Documents/universidad/biologia/Proyecto2/analysis/virtual_screening/screening/resultados_1000/scores_humana.csv"

df_hongo = pd.read_csv(hongo_csv)
df_humana = pd.read_csv(humana_csv)

# Convertir a numérico por si hay algún 'NA' y eliminar esos valores
df_hongo['score_kcal_mol'] = pd.to_numeric(df_hongo['score_kcal_mol'], errors='coerce')
df_humana['score_kcal_mol'] = pd.to_numeric(df_humana['score_kcal_mol'], errors='coerce')
df_hongo = df_hongo.dropna()
df_humana = df_humana.dropna()

# Al hacer el merge, 'score_kcal_mol_x' será Hongo y '_y' será Humana
df_todo = pd.merge(df_hongo, df_humana, on="ligando", suffixes=('_hongo', '_humana'))

print(f"Total de ligandos comparados: {len(df_todo)}")

# --- Crear el Scatterplot con Pyplot ---
plt.figure(figsize=(8, 8))

# Extraer las variables
x = df_todo["score_kcal_mol_hongo"]
y = df_todo["score_kcal_mol_humana"]

plt.xlim(-12, -4)
plt.ylim(-12, -4)
# Graficar los puntos
plt.scatter(x, y, alpha=0.6, color='purple', edgecolors='w', s=50)

# Etiquetas y título
plt.xlabel("Score Receptor Hongo (kcal/mol)", fontsize=12)
plt.ylabel("Score Receptor Humana (kcal/mol)", fontsize=12)
plt.title("Comparación de Afinidad: Hongo vs Humana", fontsize=14, pad=15)
plt.legend()



# Guardar la gráfica en un archivo para evitar errores de Qt
output_img = "/home/Mayday3003/Documents/universidad/biologia/Proyecto2/analysis/virtual_screening/scatter_plot_comparativo.png"
plt.savefig(output_img, dpi=300, bbox_inches='tight')
print(f"Scatterplot guardado exitosamente en: {output_img}")
