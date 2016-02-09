(ns helper.event
  (:require [clojure.core.match      :refer [match]]
            [clojure.data.json   :as json]
            [camel-snake-kebab.core  :as ksk]))

(defn mock-event [event_type state]
  (match [event_type state]

         [:produce :failure]  {:task     1
                               :success  "false"
                               :files    [{:url     "s3://url"
                                           :sha256  "log_file"
                                           :type    "log"}]}

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

(def mock-json-event
  (comp json/write-str mock-event))
