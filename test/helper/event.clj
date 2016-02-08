(ns helper.event
  (:require [clojure.core.match      :refer [match]]
            [camel-snake-kebab.core  :as ksk]))

(defn mock-event [event_type state]
  (match [event_type state]

         [:produce :failure]  {:task          1
                               :success       "false"}

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

(defn event-as-http-params [event]
  (->> (:metrics event)
       (map (fn [[k v]] [(str "metrics[" k "]") v]))
       (into {})
       (merge (dissoc event :metrics))))
