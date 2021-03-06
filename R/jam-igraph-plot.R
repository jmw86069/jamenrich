#
# jam_igraph() specific plot functions for igraph objects

#' Jam wrapper to plot igraph
#'
#' Jam wrapper to plot igraph
#'
#' This function is a lightweight wrapper around `igraph::plot.igraph()`
#' intended to handle `rescale=FALSE` properly, which is not done
#' in the former function (as of January 2020). The desired outcome
#' is for the `xlim` and `ylim` defaults to be scaled according to the
#' `igraph` layout. Similarly, the `vertex.size` and `vertex.label.dist`
#' parameters should also be scaled proportionally.
#'
#' You can use argument `label_factor_l=list(nodeType=c(Gene=0.01, Set=1))`
#' to hide labels for Gene nodes, and display labels for Set nodes.
#' Note that due to a quirk in `igraph`, setting `label.cex=0`
#' will revert the font to default size, and will not hide the
#' label.
#'
#' @family jam igraph functions
#' @family jam plot functions
#'
#' @param x `igraph` object to be plotted
#' @param ... additional arguments are passed to `igraph::plot.igraph()`
#' @param xlim,ylim default x and y axis limits
#' @param expand numeric value used to expand the x and y axis ranges,
#'    where `0.03` expands each size `3%`.
#' @param rescale logical indicating whether to rescale the layout
#'    coordinates to `c(-1, 1)`. When `rescale=FALSE` the original
#'    layout coordinates are used as-is without change.
#' @param node_factor numeric value multiplied by `V(x)$size` to adjust
#'    the relative size of all nodes by a common numeric scalar value.
#' @param edge_factor numeric value multiplied by `E(x)$width` to adjust
#'    the relative width of all edges by a common numeric scalar value.
#' @param label_factor numeric value multiplied by `V(x)$label.cex`
#'    and `E(x)$label.cex` to adjust the relative size of all labels on
#'    nodes and edges by a common numeric scalar value.
#' @param label_dist_factor numeric value multiplied by `V(x)$label.dist`
#'    to adjust the relative distance of all nodes labels from the node center
#'    by a common numeric scalar value.
#' @param node_factor_l,label_factor_l,label_dist_factor_l `list`
#'    of vectors, where the names of the `list` are attribute
#'    names, and the names of each vector are attributes values.
#'    The vector values are used as scalar multipliers, analogous to
#'    `node_factor`. The purpose is to apply scalar values to different
#'    subsets of nodes. For example, consider:
#'    `node_factor_l=list(nodeType=c(Gene=1, Set=2)`. The list name
#'    `"nodeType"` says to look at `vertex_attr(x, "nodeType")`. Nodes
#'    where `nodeType="Gene"` will use `1`, and where `nodeType="Set"`
#'    will use `2` as the scalar value.
#'
#' @examples
#' ## example showing how to use the list form
#' ## This form resizes nodes where V(g)$nodeType %in% "Gene" by 2x,
#' ## and resizes nodes where V(g)$nodeType %in% "Set" by 3x.
#' node_factor_l <- list(nodeType=c(Gene=2, Set=3));
#'
#' ## This form multiplies label.dist for nodeType="Gene" nodes by 1,
#' ## and multiplies label.dist for nodeType="Set" nodes by 0.5
#' label_dist_factor_l <- list(nodeType=c(Gene=1, Set=0.5))
#'
#' # jam_igraph(g, node_factor_l=node_factor_l, label_dist_factor_l=label_dist_factor_l);
#'
#' # Example using edge bundling by community detection
#' g <- igraph::make_graph("Zachary");
#' gcom <- igraph::cluster_leading_eigen(g);
#'
#' jam_igraph(g,
#'    layout=layout_with_qfr,
#'    edge_bundling="nodegroups",
#'    nodegroups=gcom,
#'    vertex.color=colorjam::group2colors(gcom$membership))
#'
#' cfuncs <- list(cluster_leading_eigen=igraph::cluster_leading_eigen,
#'    cluster_edge_betweenness=igraph::cluster_edge_betweenness,
#'    cluster_fast_greedy=igraph::cluster_fast_greedy,
#'    cluster_spinglass=igraph::cluster_spinglass)
#' opar <- par("mfrow"=c(2, 2));
#' for (i in seq_along(cfuncs)) {
#'    cfunc <- cfuncs[[i]];
#'    gcom <- cfunc(g);
#'    jam_igraph(g,
#'       layout=layout_with_qfr,
#'       edge_bundling="nodegroups",
#'       nodegroups=gcom,
#'       mark.groups=gcom,
#'       mark.expand=60,
#'       vertex.color=colorjam::group2colors(gcom$membership))
#'    title(main=names(cfuncs)[i]);
#' }
#' par(opar);
#'
#' # fancy example showing mark.groups and colorizing
#' # edges using node colors
#' gcom <- igraph::cluster_spinglass(g);
#' igraph::V(g)$color <- colorjam::group2colors(gcom$membership);
#' g <- color_edges_by_nodes(g);
#' jam_igraph(g,
#'    layout=layout_with_qfr,
#'    edge_bundling="nodegroups",
#'    nodegroups=gcom,
#'    mark.groups=gcom)
#'
#' # same but adjust midpoint of edge bundles
#' jam_igraph(g,
#'    layout=layout_with_qfr,
#'    edge_bundling="nodegroups",
#'    nodegroups=gcom,
#'    mark.groups=gcom,
#'    midpoint=c(0.4, 0.6),
#'    detail=14)
#'
#' # same but using node connections
#' jam_igraph(g,
#'    layout=layout_with_qfr,
#'    edge_bundling="connections",
#'    nodegroups=gcom,
#'    mark.groups=gcom)
#'
#' @export
jam_igraph <- function
(x,
 ...,
 xlim=c(-1, 1),
 ylim=c(-1, 1),
 expand=0.03,
 rescale=FALSE,
 node_factor=1,
 node_factor_l=NULL,
 edge_factor=1,
 edge_factor_l=NULL,
 label_factor=1,
 label_factor_l=NULL,
 label_dist_factor=1,
 label_dist_factor_l=1,
 use_shadowText=FALSE,
 plot_function=jam_plot_igraph,
 edge_bundling=c("none", "connections", "nodegroups"),
 nodegroups=NULL,
 render_nodes=TRUE,
 render_edges=TRUE,
 render_nodelabels=TRUE,
 render_groups=TRUE,
 vectorized_node_shapes=TRUE,
 verbose=FALSE,
 debug=NULL)
{
   ##
   # validate edge_bundling input
   if (length(edge_bundling) == 0) {
      edge_bundling <- "none";
   } else if (is.atomic(edge_bundling)) {
      edge_bundling <- head(intersect(edge_bundling,
         eval(formals(jam_igraph)$edge_bundling)), 1);
      if (length(edge_bundling) == 0) {
         stop("edge_bundling method not recognized")
      }
   } else if (is.function(edge_bundling)) {
      edge_function <- edge_bundling;
      edge_bundling <- "function";
   }

   params <- igraph:::i.parse.plot.params(x, list(...));
   layout <- params("plot", "layout");
   vertex.size <- params("vertex", "size");
   vertex.size2 <- params("vertex", "size2");
   vertex.label.dist <- params("vertex", "label.dist") * label_dist_factor;
   edge.width <- params("edge", "width") * edge_factor;

   if (is.function(label_factor)) {
      if (verbose) {
         jamba::printDebug("jam_igraph(): ",
            "Applying ", "label_factor(label.cex)");
      }
      vertex.label.cex <- label_factor(params("vertex", "label.cex"));
      edge.label.cex <- label_factor(params("edge", "label.cex"));
   } else {
      if (verbose) {
         jamba::printDebug("jam_igraph(): ",
            "Applying ", "label.cex * label_factor");
      }
      vertex.label.cex <- params("vertex", "label.cex") * label_factor;
      edge.label.cex <- params("edge", "label.cex") * label_factor;
   }
   if (is.function(node_factor)) {
      vertex.size <- node_factor(vertex.size);
      vertex.size2 <- node_factor(vertex.size2);
   } else {
      vertex.size <- vertex.size * node_factor;
      vertex.size2 <- vertex.size2 * node_factor;
   }


   ## label_factor_l=list(nodeType=c(Gene=1, Set=2))
   if (length(label_factor_l) > 0) {
      vertex.label.cex <- handle_igraph_param_list(x,
         attr="label.cex",
         label_factor_l,
         i_values=vertex.label.cex,
         attr_type="node")
   }
   if (length(label_dist_factor_l) > 0) {
      vertex.label.dist <- handle_igraph_param_list(x,
         attr="label.dist",
         label_dist_factor_l,
         i_values=vertex.label.dist,
         attr_type="node");
   }
   if (length(node_factor_l) > 0) {
      vertex.size <- handle_igraph_param_list(x,
         attr="size",
         node_factor_l,
         i_values=vertex.size,
         attr_type="node");
   }
   if (length(edge_factor_l) > 0) {
      vertex.size <- handle_igraph_param_list(x,
         attr="size",
         edge_factor_l,
         i_values=edge.width,
         attr_type="edge");
   }

   ## Optional axis range scaling
   if (!rescale) {
      dist_factor <- 4;
      if (min(xlim) <= min(layout[,1]) && max(xlim) >= max(layout[,1])) {
         xlim_asis <- TRUE;
      } else {
         xlim <- range(layout[,1]);
         xlim_asis <- FALSE;
      }
      if (length(debug) > 0 && any(c("vertex.label.dist","label.dist","labels") %in% debug)) {
         jamba::printDebug("jam_igraph(): ",
            "xlim before:",
            xlim);
         jamba::printDebug("jam_igraph(): ",
            "head(vertex.size, 20) before:",
            head(vertex.size, 20));
      }
      vertex.size <- vertex.size * diff(xlim) / 2;
      vertex.size2 <- vertex.size2 * diff(xlim) / 2;
      vertex.label.dist <- vertex.label.dist * diff(xlim) / dist_factor;
      if (!xlim_asis) {
         xlim <- xlim + diff(xlim) * c(-1,1) * expand;
      }
      if (min(ylim) <= min(layout[,2]) && max(ylim) >= max(layout[,2])) {
         ylim_asis <- TRUE;
      } else {
         ylim <- range(layout[,2]);
         ylim_asis <- FALSE;
         ylim <- ylim + diff(ylim) * c(-1,1) * expand;
      }
   }

   if (length(debug) > 0 && any(c("vertex.label.dist","label.dist","labels") %in% debug)) {
      jamba::printDebug("jam_igraph(): ",
         "xlim after:",
         xlim);
      jamba::printDebug("jam_igraph(): ",
         "head(vertex.label.dist, 20):",
         head(vertex.label.dist, 20));
      jamba::printDebug("jam_igraph(): ",
         "head(vertex.size, 20) after:",
         head(vertex.size, 20));
   }
   plot_function(x=x,
      ...,
      rescale=rescale,
      vertex.size=vertex.size,
      vertex.size2=vertex.size2,
      vertex.label.dist=vertex.label.dist,
      vertex.label.cex=vertex.label.cex,
      edge.label.cex=edge.label.cex,
      edge.width=edge.width,
      use_shadowText=use_shadowText,
      xlim=xlim,
      ylim=ylim,
      render_nodes=render_nodes,
      render_edges=render_edges,
      render_nodelabels=render_nodelabels,
      render_groups=render_groups,
      edge_bundling=edge_bundling,
      nodegroups=nodegroups,
      vectorized_node_shapes=vectorized_node_shapes,
      debug=debug);
}



#' Handle igraph attribute parameter list
#'
#' Handle igraph attribute parameter list, internal function for `jam_igraph()`
#'
#' This mechanism is intended to help update `igraph` attributes
#' in bulk operations by the attribute values associated with
#' nodes or edges. Most commonly, the argument `factor_l` is
#' multiplied by numeric attributes to scale attribute values,
#' for example label font size, or node size.
#'
#' For example:
#'
#' ```
#' handle_igraph_param_list(x,
#'    attr="size",
#'    factor_l=list(nodeType=c(Gene=1, Set=2)),
#'    i_values=rep(1, igraph::vcount(x)),
#'    attr_type="node")
#' ```
#'
#' This function call will match node attribute `nodeType`,
#' the size of nodes with attribute value
#' `nodeType="Set"` are multiplied `size * 2`,
#' `nodeType="Gene"` are multiplied `size * 1`.
#'
#' @return `vector` of attribute values representing `attr`.
#'
#' @family jam utility functions
#'
#' @param x `igraph` object
#' @param attr `character` name of the attribute to update in `x`.
#' @param factor_l `list` or `numeric` vector or `function`:
#'    * `list` of `numeric` vectors where `names(factor_l)`
#'    correspond to attribute names, and the names of numeric vectors
#'    are attribute values The attribute names and attribute values are
#'    used to match relevant entities of type `attr_type`.
#'    For matching entities, attribute values are used as defined by
#'    attribute name `attr`, and are multiplied by the matching
#'    numeric value in `factor_l`.
#'    * `numeric` vector which is directly multiplied by `i_values`
#'    to produce an adjusted output vector `i_values`.
#'    * `function` which is used to modify `i_values` by calling
#'    `factor_l(i_values)` to produce adjusted output `i_values`.
#' @param i_values `vector` of attribute values that represent the current
#'    attribute values in `x` for the attribute `attr`.
#' @param attr_type `character` string indicating the type of entity
#'    being adjusted in `x`:
#'    * `"node"` or `"vertex"` refers to `igraph::vertex_attr()`
#'    * `"edge"` refers to `igraph::edge_attr()`
#' @param ... additional arguments are ignored.
#'
#'
#' @export
handle_igraph_param_list <- function
(x,
 attr,
 factor_l,
 i_values=NULL,
 attr_type=c("node", "vertex", "edge"),
 verbose=FALSE,
 ...)
{
   attr_type <- match.arg(attr_type);
   if (attr_type %in% c("node", "vertex")) {
      x_attr_names <- igraph::list.vertex.attributes(x);
      if (length(i_values) == 0) {
         i_values <- igraph::vertex_attr(x, attr);
      }
   } else if (attr_type %in% c("edge")) {
      x_attr_names <- igraph::list.edge.attributes(x);
      if (length(i_values) == 0) {
         i_values <- igraph::edge_attr(x, attr);
      }
   }
   if (is.numeric(factor_l)) {
      if (verbose) {
         jamba::printDebug("jam_igraph(): ",
            "Applying ['", attr, "'] as i_values * (factor_l)");
      }
      i_values <- factor_l * i_values;
   } else if (is.function(factor_l)) {
      if (verbose) {
         jamba::printDebug("jam_igraph(): ",
            "Applying ['", attr, "'] using factor_l(i_values)");
      }
      i_values <- factor_l(i_values);
   } else if (length(factor_l) > 0 && is.list(factor_l)) {
      # iterate each name in factor_l which corresponds to node/vertex attribute names
      for (i in names(factor_l)) {
         j <- factor_l[[i]];
         # iterate the name of each vector element in factor_l[[i]]
         # to identify nodes whose attribute value matches the name
         for (k in names(j)) {
            adjust_value <- factor_l[[i]][[k]];
            if (i %in% x_attr_names) {
               if (attr_type %in% c("node", "vertex")) {
                  i_update <- (igraph::vertex_attr(x, i) %in% k);
               } else {
                  i_update <- (igraph::edge_attr(x, i) %in% k);
               }
               if (any(i_update)) {
                  if (!is.function(adjust_value)) {
                     if (is.numeric(adjust_value)) {
                        adj_label <- paste0(" ", attr_type,": ['", attr, "'] * (", adjust_value, ")");
                        i_values[i_update] <- i_values[i_update] * adjust_value;
                     } else {
                        adj_label <- paste0(" ", attr_type,": ['", attr, "'] <- '", adjust_value, "'");
                        i_values[i_update] <- adjust_value;
                     }
                  } else if (is.function(adjust_value)) {
                     adj_label <- paste0(" ", attr_type,": adjust_function(['", attr, "'])");
                     i_values[i_update] <- adjust_value(i_values[i_update]);
                  }
                  # optional verbose output
                  if (verbose) {
                     jamba::printDebug(sep="",
                        c("jam_igraph(): ",
                           "Applying ",
                           " factor_l[['",i,"']][['",k,"']] to ",
                           jamba::formatInt(sum(i_update)),
                           adj_label));
                  }
               }
            }
         }
      }
   }
   return(i_values);
}
