import pandas as pd
import matplotlib.pyplot as plt


hongo_csv = "/home/Mayday3003/Documents/universidad/biologia/Proyecto2/analysis/virtual_screening/screening/resultados_1000/scores_hongo.csv"
humana_csv = "/home/Mayday3003/Documents/universidad/biologia/Proyecto2/analysis/virtual_screening/screening/resultados_1000/scores_humana.csv"

df_hongo = pd.read_csv(hongo_csv)
df_humana = pd.read_csv(humana_csv)

datos_hongo = pd.to_numeric(df_hongo["score_kcal_mol"], errors='coerce').dropna()
datos_humana = pd.to_numeric(df_humana["score_kcal_mol"], errors='coerce').dropna()

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6), sharey=True)

ax1.hist(datos_hongo, bins=16, range=[-12, -4], color='blue', edgecolor='black')
ax1.set_xlabel("Puntuación (kcal/mol)")
ax1.set_ylabel("Frecuencia")
ax1.set_title("Receptor Hongo")
ax1.grid(axis='y', alpha=0.75)

ax2.hist(datos_humana, bins=16, range=[-12, -4], color='orange', edgecolor='black')
ax2.set_xlabel("Puntuación (kcal/mol)")
ax2.set_title("Receptor Humana")
ax2.grid(axis='y', alpha=0.75)


fig.suptitle(" Scoring de Docking", fontsize=16)

output_img = "/home/Mayday3003/Documents/universidad/biologia/Proyecto2/analysis/virtual_screening/screening/histograma_comparativo.png"
plt.savefig(output_img, dpi=300, bbox_inches='tight')
print(f"Histograma guardado exitosamente en: {output_img}")
