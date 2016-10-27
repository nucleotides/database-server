(ns helper.event
  (:require [clojure.test            :refer :all]
            [clojure.core.match      :refer [match]]
            [clojure.data.json       :as json]))

(defn mock-event [event_type state]
  (match [event_type state]

         [:produce :failure]  {:task     1
                               :success  false
                               :files    [{:url     "s3://log_file"
                                           :sha256  "42ae5"
                                           :type    "container_log"}]
                               :metrics  {}}

         [:produce :success]  {:task     1
                               :success  true
                               :metrics  {}
                               :files    [{:url     "s3://metrics"
                                           :sha256  "12def"
                                           :type    "container_runtime_metrics"},
                                          {:url     "s3://log_file"
                                           :sha256  "66b8d"
                                           :type    "container_log"},
                                          {:url     "s3://contigs"
                                           :sha256  "f7455"
                                           :type    "contig_fasta"}]}

         [:evaluate :success] {:task     2
                               :success  true
                               :files    [{:url     "s3://url"
                                           :sha256  "log_file"
                                           :type    "container_log"}]
                               :metrics  {"ng50" 20000, "lg50" 5}}

         [:evaluate :invalid-metric] (-> (mock-event :evaluate :success)
                                         (assoc-in [:metrics :unknown] 0))

         [:evaluate :invalid-file]   (-> (mock-event :evaluate :success)
                                         (assoc-in [:files 0 :type] "unknown"))

         [:produce :duplicate-file]  (-> (mock-event :produce :success)
                                         (assoc-in [:files 1 :sha256] "66b8d"))))

(def mock-json-event
  (comp json/write-str mock-event))

(defn has-event? [coll event]
  (let [events (into #{} (map #(dissoc % :created_at :id) coll))]
    (is (contains? events event))))
