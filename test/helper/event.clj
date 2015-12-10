(ns helper.event
  (:require [clojure.core.match :refer [match]]))

(defn mock-event [x]
  (match [x]

         [:success] {:task          1
                     :success       true
                     :log_file_url  "s3://url"
                     :file_url      "s3://url"
                     :file_md5      "123"}

         [:failure] {:task          1
                     :success       false
                     :log_file_url  "s3://url" }))
