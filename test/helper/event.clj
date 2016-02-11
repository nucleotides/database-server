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

         [:evaluate :success] {:task     2
                               :success  true
                               :files    [{:url     "s3://url"
                                           :sha256  "log_file"
                                           :type    "log"}]
                               :metrics  {"ng50" 20000, "lg50" 5}}))

(def mock-json-event
  (comp json/write-str mock-event))
