# Time-stamp: <2018-06-14 15:42:44 kmodi>
# Tiny utility to quick-start an ox-hugo generated Hugo site

import os, strformat, strutils, debugverbosity

const
  defaultThemeUrls = @["https://github.com/kaushalmodi/hugo-bare-min-theme"
                       , "https://github.com/kaushalmodi/hugo-search-fuse-js"
                       , "https://github.com/kaushalmodi/hugo-debugprint"]
  siteConfigContents = """
baseURL = "https://example.org/"
languageCode = "en-us"
title = "My ox-hugo generated Hugo Site"

theme = "hugo-bare-min-theme"

enableEmoji = true
enableGitInfo = true

disableFastRender = true        # Hugo 0.30

pygmentsCodeFences = true       # This applies to Chroma too.
pygmentsUseClasses = true       # This applies to Chroma too.

[Params]
  description = "Example site for the Hugo Bare Min theme."
  # Note: It is *mandatory* to set "url" below if you want to set
  # "md_dir" or "org_dir".
  [Params.source]
    url = "https://github.com/kaushalmodi/hugo-bare-min-theme" # Needed if you want to see .GitInfo for a page
    md_dir = "content"                                         # Needed if you want to get a link to Markdown source for each page
    org_dir = "content-org"                                    # Needed if you want to get a link to the Org source (e.g. when using ox-hugo!)
"""
  orgContentDir = "content-org"
  orgContentFile = "site.org"
  orgContents ="""
#+hugo_base_dir: ../

#+seq_todo: TODO DRAFT DONE
#+property: header-args :eval never-export

#+options: creator:t toc:2

#+macro: tex @@html:<span class="tex">T<sub>e</sub>X</span>@@
#+macro: latex @@html:<span class="latex">L<sup>a</sup>T<sub>e</sub>X</span>@@
#+macro: xetex @@html:<span class="xetex">X<sub>&#398;</sub>T<sub>E</sub>X</span>@@

#+macro: abbr @@html:<abbr title="$2">$1</abbr>@@
#+macro: inforef @@html:<a href="$1"><abbr title="Read the same section within Emacs by doing 'C-h i g $2'">$2</abbr></a>@@

#+macro: end @@html:<div class="center"><b>§</b></div>@@

#+macro: update - $1 :: $2

#+macro: reply @@html:<div class="reply">In reply to: <p><a class="u-in-reply-to h-cite" rel="in-reply-to" href="$1">$1</a></p></div>@@

* Homepage
:PROPERTIES:
:EXPORT_HUGO_SECTION: /
:EXPORT_HUGO_BUNDLE: /
:EXPORT_FILE_NAME: _index
:END:
Home page content
* Posts
** Emacs                                                              :@emacs:
All posts in here will have the category set to /emacs/.
*** TODO Writing Hugo blog in Org                                   :hugo:org:
:PROPERTIES:
:EXPORT_FILE_NAME: writing-hugo-blog-in-org-subtree-export
:END:
**** First heading within the post
- This post will be exported as
  =content/posts/writing-hugo-blog-in-org-subtree-export.md=.
- Its title will be "Writing Hugo blog in Org".
- It will have /hugo/ and /org/ tags and /emacs/ as category.
***** A sub-heading under that heading
- It's draft state will be marked as =true= as the subtree has the
  todo state set to /TODO/.

With the point _anywhere_ in this /Writing Hugo blog in Org/ post
subtree, do =C-c C-e H H= to export just this post.

The exported Markdown has a little comment footer as set in the /Local
Variables/ section below.
* Footnotes
* COMMENT Local Variables                                           :ARCHIVE:
# Local Variables:
# fill-column: 70
# eval: (auto-fill-mode 1)
# eval: (add-hook 'after-save-hook #'org-hugo-export-wim-to-md-after-save :append :local)
# org-hugo-footer: "\n\n[//]: # \"Exported with love from a post written in Org mode\"\n[//]: # \"- https://github.com/kaushalmodi/ox-hugo\""
# End:
"""

# Custom exception: https://forum.nim-lang.org/t/2863/1#17817
type
  ShellCmdError = object of Exception
  UserError = object of Exception

template execShellCmdSafe(cmd: string) =
  var exitStatus = execShellCmd(cmd)
  if exitStatus > 0:
    raise newException(ShellCmdError, "Failed to execute “" & cmd & "”")

# https://rosettacode.org/wiki/Handle_a_signal#Nim
# Wed May 16 18:28:02 EDT 2018 - kmodi - What does {.noconv.} do?
proc ctrlCHandler() {.noconv.} =
  echo " .. Installation canceled"
  quit 0

proc hugoNewSite(dir: string) =
  ## Create new hugo site
  dbg "Entering hugoNewSite"
  execShellCmdSafe("hugo new site " & dir)
  execShellCmdSafe("git init " & dir)

proc cloneThemes(dir: string) =
  ## Clone themes
  dbg "Entering cloneThemes"
  for url in defaultThemeUrls:
    var
      urlSplits = url.rsplit({'/'}, maxsplit = 1)
      themeName = urlSplits[1]
      themeDir = dir / "themes" / themeName
    dbg "theme url splits: {urlSplits}"
    dbg "theme name: {themeName}"
    execShellCmdSafe(fmt"git clone --recurse-submodules {url} {themeDir}")

proc updateSiteConfig(dir: string) =
  ## Update site's conmfig.toml
  dbg "Entering updateSiteConfig"
  let
    configToml = dir / "config.toml"
  removeFile(configToml)
  writeFile(configToml, siteConfigContents)

proc createOrgContent(dir: string) =
  ## Create Org Content
  dbg "Entering createOrgContent"
  let
    orgContentDirPath = dir / orgContentDir
    orgContentFilePath = orgContentDirPath / orgContentFile
  createDir(orgContentDirPath)
  writeFile(orgContentFilePath, orgContents)

proc oxHugoNim(dir: string
               , force: bool = false) =
  ##oxHugoNew: Tiny utility to quick-start an ox-hugo generated Hugo site

  # https://rosettacode.org/wiki/Handle_a_signal#Nim
  setControlCHook(ctrlCHandler)

  let
    dirPath = "." / dir

  try:
    if force and dirExists(dirPath):
      removeDir(dirPath)
    hugoNewSite(dirPath)
    # Remove the unnecessary archetypes dir
    removeDir(dirPath / "archetypes")
    cloneThemes(dirPath)
    updateSiteConfig(dirPath)
    createOrgContent(dirPath)

    echo fmt"Now open ‘{dir / orgContentDir / orgContentFile}’ in emacs and run ‘C-c C-e C-H C-H’"
  except:
    echo "[Error] " & getCurrentExceptionMsg()

when isMainModule:
  import cligen
  dispatch(oxHugoNim
           , help = {"dir" : "Name of the new Hugo site directory"
                      , "force" : "If the site directory already exists, it is first deleted!"
                    }
           , short = {"force" : 'F'
                     })
