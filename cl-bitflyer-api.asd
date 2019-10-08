(defsystem cl-bitflyer-api
  :version "0.1"
  :license "MIT"
  :depends-on (:drakma
               :ironclad
               :cl-json)
  :components ((:module "src"
                :serial t
                :components
                ((:file "cl-bitflyer-api")))))
