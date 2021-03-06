#' like a VRanges, but for mitochondria
#' 
#' @import VariantAnnotation
#' @importFrom S4Vectors endoapply
#' @importFrom VariantAnnotation filt 
#' 
#' @exportClass MVRanges
setClass("MVRanges", 
         representation(coverage="numeric"),
         contains="VRanges")


#' wrap a VRanges for mitochondrial use
#'
#' Usually the MVRanges constructor will be called by callMT(). 
#' 
#' @rdname    MVRanges-methods
#'
#' @param   vr        the VRanges
#' @param   coverage  estimated coverage
#'
#' @return            an MVRanges
#'
#' @import BiocGenerics
#'
#' @examples
#' 
#' library(MTseekerData)
#' BAMdir <- system.file("extdata", "BAMs", package="MTseekerData")
#' BAMs <- paste0(BAMdir, "/", list.files(BAMdir, pattern=".bam$"))
#' (mal <- getMT(BAMs[1]))
#' if (requireNamespace("GmapGenome.Hsapiens.rCRS", quietly=TRUE)) {
#'   (mvr <- callMT(mal))
#'   locateVariants(mvr)
#'   predictCoding(mvr) 
#' } else { 
#'   message("You have not yet installed an rCRS reference genome.")
#'   message("Consider running the indexMTgenome() function to do so.")
#'   message("An example MVRanges is RONKSvariants$RO_1 from MTseekerData.")
#' }
#' 
#' # summarizeVariants can take too long to run, and requires internet access 
#'
#' @export
MVRanges <- function(vr, coverage=NA_real_) new("MVRanges",vr,coverage=coverage)


#' MVRanges methods (centralized).
#'
#' Many of these methods can be dispatched from an MVRangesList OR an MVRanges.
#' In such cases, the method will usually, but not always, be apply()ed. 
#' 
#' @section Utility methods:
#' 
#' `pos` returns a character vector describing variant positions. 
#' `filt` returns a subset of variant calls where PASS == TRUE (i.e. filtered)
#' `coverage` returns an Rle of coverage across the mitochondrial genome
#' `genomeCoverage` returns the estimated mitochondrial read coverage depth
#'
#' @section Annotation methods:
#' 
#' `type` returns a character vector describing variant type (SNV or indel)
#' `genes` retrieves a GRanges of mitochondrial gene locations for an MVRanges
#' `snpCall` retrieves single nucleotide variant polymorphisms PASSing filters
#' `annotation` gets (perhaps oddly) an MVRanges object annotated against rCRS
#' `getAnnotations` returns the GRanges of gene/region annotations for an MVR
#' `encoding` returns variants residing in coding regions (consequence unknown)
#' `locateVariants` annotates variants w/region, gene, and localStart/localEnd
#' `predictCoding` returns variants consequence predictions as one might expect
#' `tallyVariants` returns a named vector of variant types by annotated region.
#' `summarizeVariants` uses MitImpact to attempt annotation of coding variants.
#' `consensusString` edits rCRS to create a consensus genotype for eg Haplogrep
#'
#' @section Visualization methods:
#'
#' `plot` creates a circular plot of mitochondrial variant calls with annotation
#'
#' @param x             an MVRanges
#' @param object        an MVRanges
#' @param annotations   an MVRanges
#' @param query         an MVRanges
#' @param mode          miscellaneous arguments
#' @param y             another MVRanges
#' @param varAllele     variant alleles
#' @param subject       a GRanges, usually 
#' @param seqSource     a BSgenome, usually 
#' @param ...           miscellaneous args, passed through
#' 
#' @param filterLowQual boolean; drop non-PASSing variants from locateVariants?
#'
#' @return              depends on the method invoked.
#' 
#' @aliases locateVariants getAnnotations predictCoding genes
#' @aliases snpCall annotation tallyVariants summarizeVariants
#'
#' @import              Homo.sapiens
#' 
#' @importFrom          GenomicFeatures   genes
#' @importFrom          Biobase           snpCall
#' @importFrom          graphics          plot 
#'
#' @importMethodsFrom   VariantAnnotation filt 
#' @importMethodsFrom   GenomicFeatures   genes
#' @importMethodsFrom   Biostrings        consensusString type 
#' @importMethodsFrom   IRanges           coverage
#' 
#' @name                MVRanges-methods
NULL


#' @rdname    MVRanges-methods
#' @export
setMethod("genomeCoverage", signature(x="MVRanges"), function(x) x@coverage)


#' @rdname    MVRanges-methods
#' @export
setMethod("coverage", signature(x="MVRanges"), 
          function(x) callNextMethod()[[1]]) 


#' @rdname    MVRanges-methods
#' @export
setMethod("type", signature(x="MVRanges"), 
          function(x) ifelse(nchar(ref(x)) == nchar(alt(x)), "SNV", "indel"))


#' @rdname    MVRanges-methods
#' @export
setMethod("genes", signature(x="MVRanges"), 
          function(x) subset(getAnnotations(x), region == "coding"))


#' @rdname    MVRanges-methods
#' @export
setMethod("snpCall", signature(object="MVRanges"),
          function(object) subset(object, nchar(alt) == nchar(ref)))


#' @rdname    MVRanges-methods
#' @export
setMethod("pos", signature(x="MVRanges"), 
          function(x) {
            .getse <- function(y) cbind(start(y), end(y))
            .condense <- function(y) paste(unique(y), collapse="_")
            apply(.getse(granges(x)), 1, .condense)
          })


#' @rdname    MVRanges-methods
#' @export
setMethod("show", signature(object="MVRanges"),
          function(object) {
            callNextMethod()
            cat(paste0("  genome: ", genome(object)))
            if ("annotation" %in% names(metadata(object))) {
              cat(" (try getAnnotations(object))")
            }
            cat(paste0(", ~",round(genomeCoverage(object)),"x read coverage")) 
            cat("\n")
          })


#' @rdname    MVRanges-methods
#' @export
setMethod("annotation", signature(object="MVRanges"), 
          function(object) {

            if (!"annotation" %in% names(metadata(object))) {
              data(mtAnno.rCRS)
              metadata(object)$annotation <- mtAnno
            }

            anno <- getAnnotations(object)
            ol <- findOverlaps(object, anno)
            object$gene <- NA_character_
            object[queryHits(ol)]$gene <- names(anno)[subjectHits(ol)] 
            object$region <- NA_character_
            object[queryHits(ol)]$region <- anno[subjectHits(ol)]$region
            return(object)

          })

# previously defined in chromvar
setGeneric("getAnnotations",
           function(annotations, ...) standardGeneric("getAnnotations"))

#' @rdname    MVRanges-methods
#' @export
setMethod("getAnnotations", signature(annotations="MVRanges"), 
          function(annotations) {
            if (is.null(metadata(annotations)$annotation)) {
              data(mtAnno.rCRS)
              return(mtAnno)
            } else { 
              return(metadata(annotations)$annotation)
            }
          })


#' @rdname    MVRanges-methods
#' @export
setMethod("encoding", signature(x="MVRanges"), 
          function(x) {

            # limit the search 
            x <- locateVariants(x) 
            x <- subset(x, region == "coding") 
            chrM <- grep("(MT|chrM|rCRS|RSRS)", seqlevelsInUse(x), value=TRUE)
            return(keepSeqlevels(x, chrM, pruning.mode="coarse"))

          })


#' @rdname    MVRanges-methods
#' @importFrom VariantAnnotation filt
#' @export
setMethod("filt", signature(x="MVRanges"), function(x) subset(x, x$PASS==TRUE))


#' @rdname    MVRanges-methods
#' @export
setMethod("genome", signature(x="MVRanges"), 
          function(x) unique(seqinfo(x)@genome))


#' @rdname    MVRanges-methods
#' @export
setMethod("locateVariants", 
          signature(query="MVRanges","missing","missing"),
          function(query, filterLowQual=FALSE, ...) {
            if (filterLowQual == TRUE) query <- filt(query)
            if ("gene" %in% names(mcols(query)) &
                "region" %in% names(mcols(query)) &
                "localEnd" %in% names(mcols(query)) & 
                "localStart" %in% names(mcols(query)) &
                "startCodon " %in% names(mcols(query)) &
                "endCodon" %in% names(mcols(query))) {
              return(query) # done 
            }
            if (length(query) == 0) return(NULL)
            
            data("mtAnno.rCRS", package="MTseeker")
            metadata(query)$annotation <- mtAnno
            
            ol <- findOverlaps(query, mtAnno, ignore.strand=TRUE)
            query$gene <- NA_character_
            query$overlapGene <- NA_character_
            #check if we picked up a hit in overlapping genes
            #NOTE: this ignores strand if overlapping hits based on above
            if (length(names(mtAnno)[subjectHits(ol)]) > 1) {
              #pick off the first gene name
              query[queryHits(ol)]$gene <- names(mtAnno)[subjectHits(ol)][1]
              query[queryHits(ol)]$overlapGene <- paste(names(mtAnno)[subjectHits(ol)],
                                                        collapse = ",")
            } else {
              query[queryHits(ol)]$gene <- names(mtAnno)[subjectHits(ol)]
            }
            #query[queryHits(ol)]$gene <- names(mtAnno)[subjectHits(ol)] 
            query$region <- NA_character_
            query[queryHits(ol)]$region <- mtAnno[subjectHits(ol)]$region
            
            ## Localized genic coordinates
            anno <- subset(mtAnno, region == "coding") 
            ol2 <- findOverlaps(query, anno, ignore.strand=TRUE)
            query$localStart <- NA_integer_
            #check if we picked up a hit in overlapping genes
            if (length(start(query[queryHits(ol2)]) - start(anno[subjectHits(ol2)])) > 1) {
              dnaStart <- 
                start(query[queryHits(ol2)]) - start(anno[subjectHits(ol2)])
              #be consistent with first start
              #could add a check here to make sure we have the same gene
              query[queryHits(ol2)]$localStart <- dnaStart[1]
            } else {
              query[queryHits(ol2)]$localStart <- 
                start(query[queryHits(ol2)]) - start(anno[subjectHits(ol2)])
            }
            query$localEnd <- NA_integer_
            if (length(end(query[queryHits(ol2)]) - start(anno[subjectHits(ol2)])) > 1) {
              dnaEnd <- 
                end(query[queryHits(ol2)]) - start(anno[subjectHits(ol2)])
              #be consistent with first end
              #could add a check here to make sure we have the same gene
              query[queryHits(ol2)]$localEnd <- dnaEnd[1]
            } else {
              query[queryHits(ol2)]$localEnd <- 
                end(query[queryHits(ol2)]) - start(anno[subjectHits(ol2)])
            }
            
            ## Affected reference codon(s)
            query$startCodon <- NA_integer_
            #check if we picked up overlapping genes
            if (length(query[queryHits(ol2)]$localStart %/% 3) > 1) {
              aaStart <- query[queryHits(ol2)]$localStart %/% 3
              query[queryHits(ol2)]$startCodon <- aaStart[1]
            } else {
              query[queryHits(ol2)]$startCodon <- 
                query[queryHits(ol2)]$localStart %/% 3
            }
            query$endCodon <- NA_integer_
            if (length(query[queryHits(ol2)]$localEnd %/% 3) > 1) {
              aaEnd <- query[queryHits(ol2)]$localEnd %/% 3
              query[queryHits(ol2)]$endCodon <- aaEnd[1]
            } else {
              query[queryHits(ol2)]$endCodon <- 
                query[queryHits(ol2)]$localEnd %/% 3
            }
            
            return(query)
            
          })


#' @rdname    MVRanges-methods
#' @export
setMethod("tallyVariants", signature(x="MVRanges"), 
          function(x, filterLowQual=TRUE, ...) {

            located <- locateVariants(x, filterLowQual=filterLowQual)
            table(located$region)

          })


#' @rdname    MVRanges-methods
#' @export
setMethod("predictCoding", # mitochondrial annotations kept internally
          signature(query="MVRanges", "missing", "missing", "missing"), 
          function(query, ...) injectMTVariants(filt(query)))


#' @rdname    MVRanges-methods
#' @import    jsonlite
#' @export
setMethod("summarizeVariants", signature(query="MVRanges","missing","missing"),
          function(query, ...) {
          
            # helper function  
            getImpact <- function(pos) {
              url <- paste("http://mitimpact.css-mendel.it", "api", "v2.0",
                           "genomic_position", sub("^(g|m)\\.","",pos), sep="/")
              res <- as.data.frame(read_json(url, simplifyVector=TRUE)$variants)
              if (nrow(res) > 0) {
                res$genomic <- with(res, paste0("m.", Start, Ref, ">", Alt))
                res$protein <- with(res, paste0("p.",AA_ref,AA_position,AA_alt))
                res$change <- with(res, paste(Gene_symbol, protein))
                res[, c("genomic","protein","change","APOGEE_boost_consensus",
                        "MToolBox","Mitomap_Phenotype","Mitomap_Status",
                        "OXPHOS_complex","dbSNP_150_id","Codon_substitution")]
              } else {
                return(NULL)
              }
            }

            hits <- lapply(pos(encoding(query)), getImpact)
            hits <- hits[which(sapply(hits, length) > 0)] 

            # be precise, if possible
            for (h in names(hits)) {
              j <- hits[[h]]
              if (h %in% j$genomic) hits[[h]] <- j[which(j$genomic == h),]
            }

            do.call(rbind, hits)

          })


#' @rdname    MVRanges-methods
#' @export
setMethod("plot", signature(x="MVRanges"), 
          function(x, ...) MTcircos(x, ...))


#' @rdname    MVRanges-methods
#' @export
setMethod("consensusString", signature(x="MVRanges"), 
          function(x, ...) {
            supported <- c("rCRS")
            actual <- unique(genome(x))
            stopifnot(unique(genome(x)) %in% supported)
            data(rCRSeq, package="MTseeker")
            mvr <- snpCall(filt(x)) # gross
            alts <- DNAStringSet(replaceAt(rCRSeq[[1]], ranges(mvr), alt(mvr)))
            names(alts) <- actual # genome 
            return(alts)
          })
