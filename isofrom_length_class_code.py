import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns


file1 = 'P29702_301.transcriptome_isoform_length.tsv'
file2 = 'P29702_303.transcriptome_isoform_length.tsv'
file3 = 'P29702_401.transcriptome_isoform_length.tsv'

# Load TSV files
df1 = pd.read_csv(file1, sep='\t')
df2 = pd.read_csv(file2, sep='\t')
df3 = pd.read_csv(file3, sep='\t')

# Add method identifier
df1['method'] = 'PCS111'
df2['method'] = 'FLTseq'
df3['method'] = 'PCA001'

# Combine all data
df = pd.concat([df1, df2, df3], ignore_index=True)

# Check data
print(df[['chr', 'start', 'end', 'length', 'class_code', 'method']].head())

# Plot length distribution by method and class_code
plt.figure(figsize=(14, 7))
sns.boxplot(x='method', y='length', hue='class_code', data=df, showfliers=False)
plt.title('Isoform Length Distribution by Method and Class Code')
plt.ylabel('Isoform Length (bp)')
plt.xlabel('Sequencing Methods')
plt.legend(title='Class Code')
plt.tight_layout()
plt.show()





