# bfapi-wrapper

bitflyer api wrapper for Common Lisp

## Usage

```lisp
> (ql:quickload :bfapi-wrapper)
> (bfapi-wrapper:get-balance "api-key" "api-secret")
```
## Installation

1. git clone to the home directory
2. ros run
3. (asdf:initialize-source-registry '(:source-registry (:tree (:home "bfapi-wrapper")) :inherit-configuration)) 
