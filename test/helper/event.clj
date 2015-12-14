(ns helper.event
  (:require [clojure.core.match :refer [match]]))

(defn mock-event [event_type state]
  (match [event_type state]

         [_ :failure]         {:task          1
                               :success       "false"
                               :log_file_url  "s3://url" }

         [:produce :success]  {:task          1
                               :success       "true"
                               :log_file_url  "s3://url"
                               :file_url      "s3://url"
                               :file_md5      "123"}

         [:evaluate :success] {:task          1
                               :success       "true"
                               :log_file_url  "s3://url"
                               :file_url      "s3://url"
                               :file_md5      "123"
                               :metrics       {"ng50" 20000, "lg50" 5}}))
