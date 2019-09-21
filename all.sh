#!/bin/bash
if [ $# -ne 1 ];then
  echo "#usage: sh $0 [samplename]"
  exit
fi

SAMPLE=$1
BWA="/data/etc/bwa/bwa"
SAMTOOLS="/data/etc/samtools/bin/samtools"
REFERENCE="/data/reference/ucsc.hg19.fasta"
JAVA="/usr/bin/java"
PICARD="/data/etc/picard/picard.jar"
GATK="/data/etc/gatk/GenomeAnalysisTK.jar"
SNPEFF="/data/etc/snpEff/snpEff.jar"
MILLS="/data/etc/bundle/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf"
A1KG="/data/etc/bundle/1000G_phase1.indels.hg19.sites.vcf"
DBSNP138="/data/etc/bundle/dbsnp_138.hg19.vcf"
'''
${BWA} mem -R "@RG\tID:test\tSM:${SAMPLE}\tPL:ILLUMINA" ${REFERENCE} ${SAMPLE}_1.filt.fastq.gz ${SAMPLE}_2.filt.fastq.gz | ${SAMTOOLS} view -Sb - | ${SAMTOOLS} sort - > ${SAMPLE}.sorted.bam

${JAVA} -jar ${PICARD} MarkDuplicates I=${SAMPLE}.sorted.bam O=${SAMPLE}.markdup.bam M=${SAMPLE}.markdup.metrics.txt

${SAMTOOLS} index ${SAMPLE}.markdup.bam

${JAVA} -jar ${GATK} -T RealignerTargetCreator -R ${REFERENCE} -I ${SAMPLE}.markdup.bam -known ${MILLS} -known ${A1KG} -o ${SAMPLE}.intervals #-L bed

${JAVA} -jar ${GATK} -T IndelRealigner -R ${REFERENCE} -I ${SAMPLE}.markdup.bam -known ${MILLS} -known ${A1KG} -targetIntervals ${SAMPLE}.intervals -o ${SAMPLE}.realign.bam

${JAVA} -jar ${GATK} -T BaseRecalibrator -R ${REFERENCE} -I ${SAMPLE}.realign.bam -knownSites ${MILLS} -knownSites ${A1KG} -knownSites ${DBSNP138} -o ${SAMPLE}.table #-L bed

${JAVA} -jar ${GATK} -T PrintReads -R ${REFERENCE} -I ${SAMPLE}.realign.bam -o ${SAMPLE}.recal.bam -BQSR ${SAMPLE}.table #-L bed
'''
${JAVA} -jar ${GATK} -T HaplotypeCaller -R ${REFERENCE} -I ${SAMPLE}.recal.bam --emitRefConfidence GVCF --dbsnp ${DBSNP138} -o ${SAMPLE}.g.vcf #-L bed

${JAVA} -jar ${GATK} -T GenotypeGVCFs -R ${REFERENCE} -V ${SAMPLE}.g.vcf -o ${SAMPLE}.raw.vcf #-L bed
