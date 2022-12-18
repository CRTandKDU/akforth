;; Straight from [[https://sources.debian.org/src/lsp-mode/6.0-1/lsp-clients.el/]]

(defun lsp-forth--lsp-command ()
  "Generate LSP startup command."
  `("node"
    "C:\\Users\\jmchauvet\\Documents\\forth\\blacklist-server\\index.js"
    "--stdio")
  )

(lsp-register-client
 (make-lsp-client :new-connection (lsp-stdio-connection 'lsp-forth--lsp-command)
                  :major-modes '(forth-mode)
                  :priority -1
                  :server-id 'forth-ls))
