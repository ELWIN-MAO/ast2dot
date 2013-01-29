ast2dot
=======

Recently I have been creating GCC plugins to automatically and transparently add security mechanisms to software at compile time. I enjoy the work tremendously. Part of the work requires an understanding of GCCs intermediate representations including the abstract syntax tree (AST).

The AST can be difficult to grok. Therefore, I created a simple utility that converts a GCC AST dump into the DOT graph description language. Once the tree is represented by the DOT format it can be visualized using various diagramming tools such as GraphViz, or my favorite for the Mac, OmniGraffle.

http://infinitesteps.blogspot.com/2013/01/ast2dot-script-to-help-visualize-gcc-ast.html
