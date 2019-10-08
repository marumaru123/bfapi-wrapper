# cl-bitflyer-api

bitflyer api by Common Lisp

## Usage

```lisp
> (ql:quickload :cl-bitflyer-api)
> (cl-bitflyer-api:get-balance "api-key" "api-secret")
```
## Installation

1. git clone to the home directory
2. ros run
3. (asdf:initialize-source-registry '(:source-registry (:tree (:home "cl-bitflyer-api")) :inherit-configuration)) 
