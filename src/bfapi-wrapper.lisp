(in-package :cl-user)
(defpackage bfapi-wrapper
  (:use :cl
        :drakma
        :ironclad
        :cl-json)
  (:export :get-markets :get-board :get-ticker :get-executions :get-board-state :get-health :get-permissions :get-balance :send-child-order :cancel-child-order :cancel-all-child-orders :get-child-orders :get-trade-executions))
(in-package :bfapi-wrapper)

(defparameter *endpoint-url*     "https://api.bitflyer.com")
(defparameter *api-content-type* "application/json")

(defun hex (bytes)
  (ironclad:byte-array-to-hex-string bytes))

(defun hmac_sha256 (secret text)
  (let ((hmac (ironclad:make-hmac (ironclad:ascii-string-to-byte-array secret) :sha256)))
    (ironclad:update-hmac hmac (ironclad:ascii-string-to-byte-array text))
    (ironclad:hmac-digest hmac)))

(defun get-timestamp ()
  (multiple-value-bind (time1 ms1) (sb-unix::system-real-time-values)
    (parse-integer (concatenate 'string (princ-to-string time1) (princ-to-string ms1)))))

(defun create-extra-headers (key timestamp sign)
  (list (cons "ACCESS-KEY"       key)
	(cons "ACCESS-TIMESTAMP" timestamp)
	(cons "ACCESS-SIGN"      sign)
        (cons "Content-Type"     *api-content-type*)))

(defun get-public-api (path)
  (let* ((drakma:*drakma-default-external-format* :utf-8)
	 (drakma:*text-content-types* '(("application" . "json")))
	 (url           (concatenate 'string *endpoint-url* path))
         (extra-headers (list (cons "Content-Type" *api-content-type*))))
    (drakma:http-request url
                         :user-agent          :explorer
	                 :method              :get
	                 :content-type        *api-content-type*
	                 :external-format-out :utf-8
                         :external-format-in  :utf-8
                         :additional-headers  extra-headers)))

(defun get-private-api (key secret path)
  (let* ((drakma:*drakma-default-external-format* :utf-8)
	 (drakma:*text-content-types* '(("application" . "json")))
	 (method        "GET")
	 (timestamp     (get-timestamp))
	 (text          (concatenate 'string (princ-to-string timestamp) method path))
	 (sign          (hex (hmac_sha256 secret text)))
	 (url           (concatenate 'string *endpoint-url* path))
	 (extra-headers (create-extra-headers key timestamp sign)))
    (drakma:http-request url
                         :user-agent          :explorer
	                 :method              :get
	                 :content-type        *api-content-type*
	                 :external-format-out :utf-8
                         :external-format-in  :utf-8
                         :additional-headers  extra-headers)))

(defun post-private-api (key secret path body)
  (let* ((drakma:*drakma-default-external-format* :utf-8)
	 (drakma:*text-content-types* '(("application" . "json")))
	 (method        "POST")
	 (timestamp     (get-timestamp))
	 (json-body     (json:encode-json-to-string body))
         (text          (concatenate 'string (princ-to-string timestamp) method path json-body))
	 (sign          (hex (hmac_sha256 secret text)))
	 (url           (concatenate 'string *endpoint-url* path))
	 (extra-headers (create-extra-headers key timestamp sign)))
    (drakma:http-request url
                         :user-agent          :explorer
	                 :method              :post
	                 :content-type        *api-content-type*
	                 :external-format-out :utf-8
                         :external-format-in  :utf-8
                         :content             json-body
                         :additional-headers  extra-headers)))

(defun get-markets ()
  (let ((path "/v1/getmarkets"))
    (get-public-api path)))

(defun get-board (product-code)
  (let ((path (concatenate 'string "/v1/getboard?product_code=" product-code)))
    (get-public-api path)))

(defun get-ticker (product-code)
  (let ((path (concatenate 'string "/v1/getticker?product_code=" product-code)))
    (get-public-api path)))

(defun get-executions (product-code)
  (let ((path (concatenate 'string "/v1/getexecutions?product_code=" product-code)))
    (get-public-api path)))

(defun get-board-state (product-code)
  (let ((path (concatenate 'string "/v1/getboardstate?product_code=" product-code)))
    (get-public-api path)))

(defun get-health (product-code)
  (let ((path (concatenate 'string "/v1/gethealth?product_code=" product-code)))
    (get-public-api path)))

(defun get-permissions (key secret)
  (let* ((path          "/v1/me/getpermissions"))
    (get-private-api key secret path)))

(defun get-balance (key secret)
  (let* ((path          "/v1/me/getbalance"))
    (get-private-api key secret path)))

(defun send-child-order (key secret product-code child-order-type side price size minute-to-expire time-in-force)
  (let* ((path          "/v1/me/sendchildorder")
	 (body          (list (cons :product_code     product-code)
			      (cons :child_order_type child-order-type)
			      (cons :side             side)
			      (cons :price            price)
			      (cons :size             size)
			      (cons :minute_to_expire minute-to-expire)
			      (cons :time_in_force    time-in-force))))
    (post-private-api key secret path body)))

(defun cancel-child-order (key secret product-code child-order-acceptance-id)
  (let* ((path          "/v1/me/cancelchildorder")
	 (body          (list (cons :product_code     product-code)
			      (cons :child_order_acceptance_id child-order-acceptance-id))))
    (post-private-api key secret path body)))

(defun cancel-all-child-orders (key secret product-code)
  (let* ((path          "/v1/me/cancelallchildorders")
	 (body          (list (cons :product_code     product-code))))
    (post-private-api key secret path body)))

(defun get-child-orders (key secret product-code child-order-acceptance-id)
  (let ((path (concatenate 'string "/v1/me/getchildorders?product_code=" product-code "&child_order_acceptance_id=" child-order-acceptance-id)))
    (get-private-api key secret path)))

(defun get-trade-executions (key secret &key (product-code "BTC_JPY") (count 100) (before 0) (after 0) (child-order-acceptance-id nil child-order-acceptance-id-supplied-p))
  (let ((path (if child-order-acceptance-id-supplied-p
		  (concatenate 'string "/v1/me/getexecutions?product_code=" product-code "&count=" (write-to-string count) "&before=" (write-to-string before) "&after=" (write-to-string after) "&child_order_acceptance_id=" child-order-acceptance-id)
		  (concatenate 'string "/v1/me/getexecutions?product_code=" product-code "&count=" (write-to-string count) "&before=" (write-to-string before) "&after=" (write-to-string after)))))
    (get-private-api key secret path)))
