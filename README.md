# TeXML -- A toy markup language for both TeX and HTML output

## Goals

I tried to use this in my blog to generate both HTML and PDF output, the 
main building blocks I wish to support is

* inline formatting
** emph, [link][http://www.google.com], <code>code</code>
* math
** inline math $x^2$
** block math $$x^2$$
* labeling and in-page ref
* image
** floated images
** figure with caption
** thumbnails (subfigures)
* list
* bibtex citing
* code highlighting

## Syntax

### Math

Inline math is wrapped with $x^2$. And display math must be on its own block

    $$
    \int_0^\infty x^2 dx
    $$
    
### Inline command

inline command is with the syntax <code>\cmdname{arg1}{arg2}{key1: value1}{key2: value2}</code>.

* number of arguments and keyed arguments are not limited
* in keyed argument, there must be at least one space after the colon (see the <code>link</code> command for why)
* inline command can be nested

#### Built-in inline command

* \emph{text}
* \link{http://www.google.com}{text: Google}

### Literal escape

use <code>@{content}</code> to prevent the content from being parsed and translated.

### Block command

Block command have the following syntax

    \s:cmdName{arg1}{arg2}{key1: value1}
    here is the content
    \e:cmdName

The content of the block is also parsed. To prevent the content from being parsed,
e.g. the code block. Use the following syntax

    \s:@cmdName{arg1}{arg2}{key1: value1}
    here is the content
    \e:cmdName

#### Built-in block command

* blockquote{source: }
* code{lang: text}

