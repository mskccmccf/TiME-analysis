### Processing of bulk RNA-seq data from 14 BCC samples for co-expression gene module analysis ###

## Packages needed 
library(edgeR)
library(tidyverse)
library("AnnotationDbi")
library("org.Hs.eg.db")
library(ggplot2)

# load raw files and normalize with TMM followed by log2 transformation using edgeR, filtering out lowly expressed genes
allcounts <- read.delim("all_RAWcounts.txt", header = TRUE, stringsAsFactors = FALSE) 
counts <- column_to_rownames(allcounts, var = "ensg")
countsm <- as.matrix(counts)
# Normalize using TMM in edgeR
y <- DGEList(counts=countsm) # read in counts matrix as DGEList in edgeR
y <- calcNormFactors(y, method = "TMM") # normalize counts using TMM; normalizes library sizes by finding scaling factors that minimizes logFC between samples for most genes
y <- round(cpm(y, prior.count = 1, log = TRUE, normalized.lib.sizes = TRUE), 4) # log transform cpm counts while maintaining effective library size
keep <- rowSums(y > 0) >= 8 # only keep rows whose cpm is greater than 0 in at least 8 samples to filter lowly expressed genes across replicates in a condition  
counts.norm.log <- as.data.frame(y[keep,]) #17,292 genes result from filtering
counts.norm.logdf <- as.data.frame(counts.norm.log)
counts.norm.logdftidy <- rownames_to_column(counts.norm.logdf, var = 'id')

counts.norm.logdftidy$symbol = mapIds(org.Hs.eg.db,
                                      keys=counts.norm.logdftidy$id, #Column containing Ensembl gene ids
                                      column="SYMBOL",
                                      keytype="ENSEMBL",
                                      multiVals="first")

write.table(counts.norm.logdftidy, "cpmnormlog2_filtergeneid_inputcemi.txt", col.names = TRUE, row.names = FALSE, sep = "\t")

### Run CEMiTool ###
library(quantreg)
library(conquer)
library(CEMiTool)

data <- counts.norm.logdftidy
datatidy <- data %>% distinct(symbol, .keep_all = TRUE) 
datatidy2 <- datatidy %>% drop_na(symbol)
datatidy2 <- column_to_rownames(datatidy2, var="symbol") 

# use cemitool function to perform co-expression module analysis 
cem <- cemitool(datatidy2)

cem <- cemitool(datatidy2, filter = TRUE, filter_pval = 0.1, apply_vst = FALSE, cor_method = c("pearson"))

# summary of cem
cem

# inspect modules
nmodules(cem)
head(module_genes(cem))
# not correlated modules contained genes that were not clustered into any module 
find_modules(cem)
# Identify top genes with the highest connectivity in each module
hubs <- get_hubs(cem,10)
summary <- mod_summary(cem)
generate_report(cem) # save report in directory
write_files(cem) # save tables in directory
save_plots(cem, "all") # save plots in directory

# load phenotype file for inflammatory groups
pheno <- read.delim("Iphenotype.txt", header = TRUE, stringsAsFactors = FALSE)
# run cemitool with sample annotation
cem <- cemitool(datatidy2, pheno)
# generate heatmap of gene set enrichment analysis
# Evaluate how modules are regulated between classes using GSEA
# visualize the enrichment score for a module in each class normalised by the number of genes in the module
cem <- mod_gsea(cem)
cem <- plot_gsea(cem)
show_plot(cem, "gsea")
hubs <- get_hubs(cem,n)

# plot gene expression within each module
cem <- plot_profile(cem)
plots <- show_plot(cem, "profile")
plots[8]

# read GMT file
# immunologic signatures (c7) gene set downloaded from broad gsea MsigDB 
gmt_in <- read_gmt("c7.all.v7.5.1.symbols.gmt")

# perform over representation analysis
cem <- mod_ora(cem, gmt_in)
# plot ora results
cem <- plot_ora(cem)
plots <- show_plot(cem, "ora")
plots[7]

ora <- ora_data(cem)

# add interactions
# file contains sets of genes identified to interact based on GRNs from Gtex compiled in TissueNexus database
# start with t_lymphocyte interactions
# read interactions
tcell <- read.delim("t_lymphocyte.txt", header=FALSE) # repeat for blood, skin and macrophage

# plot interactions
interactions_data(cem) <- tcell # add interactions
cem <- plot_interactions(cem) # generate plot
plots <- show_plot(cem, "interaction") # view the plot for the first module
bloodM2 <- plots[2]
bloodM2

# run the entire tool combined for identifying modules, correlating modules with phenotypes, determining enriched pathways, and finding interactions with known T cell genes
cem <- cemitool(datatidy2, pheno, gmt_in, interactions=tcell, 
                filter=TRUE, plot=TRUE, verbose=TRUE)

# create report as html document
generate_report(cem, directory="./Report")

# write analysis results into files
write_files(cem, directory="./Tables")

# save all plots
save_plots(cem, "all", directory="./Plots")

### generate sig DEG list with edgeR ###
allcounts <- read.delim("all_RAWcounts.txt", header = TRUE, stringsAsFactors = FALSE) # 60,237 genes
counts <- column_to_rownames(allcounts, var = "ensg")
countsm <- as.matrix(counts)

# set up design matrix to compare RCM inflamm high to inflamm low phenotype groups, 2 levels
group <- factor(c("low","low", "low", "high", "low", "high", "high", "high", "low",
                  "high", "high", "high", "high", "low"))

# read in counts and groups as DGElist
y <- DGEList(counts=countsm, group=group)
keep <- filterByExpr(y)
y <- y[keep,,keep.lib.sizes=FALSE]
y <- calcNormFactors(y)
design <- model.matrix(~group)
y <- estimateDisp(y,design)

# perform pairwise comparison between two groups defined by RCM phenotyping using qCML
et <- exactTest(y)
topTags(et)

# save exact test results comparing low to high groups with logFC, logCPM, PValue, and FDR output stats
lowvhigh_pairwisecomp <- topTags(et, n=Inf)
lowvhigh_pairwisecomp <- as.data.frame(lowvhigh_pairwisecomp) # 21,082
lowvhigh_pairwisecomptidy <- rownames_to_column(lowvhigh_pairwisecomp, var="id")

# add gene symbol annotation to DEGs
lowvhigh_pairwisecomptidy$symbol = mapIds(org.Hs.eg.db,
                                          keys=lowvhigh_pairwisecomptidy$id, #Column containing Ensembl gene ids
                                          column="SYMBOL",
                                          keytype="ENSEMBL",
                                          multiVals="first")

# subset for significance
pns <- lowvhigh_pairwisecomptidy[(lowvhigh_pairwisecomptidy$FDR > 0.05),] 
pposFCsig <- subset(lowvhigh_pairwisecomptidy, lowvhigh_pairwisecomptidy$FDR < 0.05 & lowvhigh_pairwisecomptidy$logFC > 0) 
pnegFCsig <- subset(lowvhigh_pairwisecomptidy, lowvhigh_pairwisecomptidy$FDR < 0.05 & lowvhigh_pairwisecomptidy$logFC < 0)

### Correlate module eigengene values with RCM phenotypes ###
# load in eigengene values
modeigen <- read.delim("summary_eigengene.txt", header = TRUE, stringsAsFactors = FALSE)
# load in RCM phenotypes
rcmall <- read.delim("allrcm.txt", header = TRUE, stringsAsFactors = FALSE)

modeigentidy <- gather(modeigen, 'P5','P6','P21', 'P23', 'P26', 'P27', 'P33', 'P34','P7', 'P14', 'P17', 'P20', 'P22', 'P29', key="sample",
                       value="eigenvalue")

# join rcm phenotypes with M2 and M5 modules eigengene values

M2 <- modeigentidy %>%
  filter(modules == "M2")

M5 <- modeigentidy %>%
  filter(modules == "M5")

rcmmodeigen <- inner_join(rcmall, M2, by = 'sample')

rcmmodeigen <- rcmmodeigen %>%
  select(-modules) 

rcmmodeigen <- rcmmodeigen %>%
  rename(M2eigen="eigenvalue")

rcmmodeigen <- inner_join(rcmmodeigen, M5, by = 'sample')

rcmmodeigen <- rcmmodeigen %>%
  select(-modules) 

rcmmodeigen <- rcmmodeigen %>%
  rename(M5eigen="eigenvalue")

rcmmodeigentidy <- column_to_rownames(rcmmodeigen, var="sample")

# compute correlation matrix

library(Hmisc)
library(corrplot)
library(PerformanceAnalytics)

rcm_eigen_corr2 <- rcorr(as.matrix(rcmmodeigentidy), type = c("spearman"))
# Extract the correlation coefficients
rcm_eigen_corr2$r
# Extract p-values
rcm_eigen_corr2$P

# Function to format correlation matrix with 4 columns containing rownames, column names, correlation coefficients, and pvalues of the correlation
flattenCorrMatrix <- function(cormat, pmat) {
  ut <- upper.tri(cormat)
  data.frame(
    row = rownames(cormat)[row(cormat)[ut]],
    column = rownames(cormat)[col(cormat)[ut]],
    cor  =(cormat)[ut],
    p = pmat[ut]
  )
}

flattenCorrMatrix(rcm_eigen_corr2$r, rcm_eigen_corr2$P)

group <- c("Ihigh", "Ihigh", "Ilow", "Ilow", "Ilow", "Ilow", "Ihigh", "Ilow", "Ihigh",
           "Ihigh", "Ihigh", "Ilow", "Ihigh", "Ihigh")

rcmmodeigentidy1 <- cbind(rcmmodeigentidy, group)

# scatterplot for relationship between M5 module gene expression and infiltrating myeloid cells
ggscatter(rcmmodeigentidy1, x = "M5eigen", y = "InflammationMyeloid",
          add = "reg.line", conf.int = TRUE,
          cor.coef = TRUE, cor.method = "spearman",
          xlab = "M5eigen", ylab = "Infiltrating Myeloid")

# check for normality
ggqqplot(rcmmodeigentidy$InflammationMyeloid, ylab="Myeloid")

# plot correlation between M2 and M5 against RCM measurements

m2m5 <- rcmmodeigentidy %>%
  select("M2eigen", "M5eigen")

time <- rcmall %>%
  column_to_rownames(., var="sample")

modcorrtime <- cor(m2m5, time, method = "spearman")
corrplot(modcorrtime, method = "ellipse")
