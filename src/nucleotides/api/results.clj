(ns nucleotides.api.results
  (:require [clojure.java.io                  :as io]
            [clojure.data.csv                 :as csv]
            [yesql.core                       :refer [defqueries]]
            [ring.util.io                     :refer [piped-input-stream]]
            [nucleotides.database.connection  :as con]
            [nucleotides.api.util             :as util]))

(defqueries "nucleotides/api/results.sql")

(def field-mappings
  [[:benchmark_type_name     :biological_sources  [:image_type]]
   [:biological_source_name  :file_sets           [:biological_source_type]]
   [:input_file_set_name     :files               [:run_mode :protocol :material :extraction_method :platform]]
   [:input_file_id           :images]
   [:image_name              :versions]
   [:image_version           :image_tasks]
   [:image_task              :metrics             [:benchmark_id :benchmark_name]]])

(defn json-grouped-output [fields data]
  (if (empty? fields)
    data
    (let [[parent-key child-key associated-keys] (first fields)]
      (map (fn [[parent child]]
             (merge
               (select-keys (first child) associated-keys)
               {parent-key  parent
                child-key   (->> child
                                 (map #(apply dissoc % parent-key associated-keys))
                                 (json-grouped-output (drop 1 fields)))}))
           (group-by parent-key data)))))


(defn csv-output [data-seq]
  (let [headers     (map name (keys (first data-seq)))
        rows        (map vals data-seq)
        stream-csv  (fn [out] (csv/write-csv out (cons headers rows))
                              (.flush out))]
    (piped-input-stream #(stream-csv (io/make-writer % {})))))


(defn complete
  "Returns metrics for each completed benchmark instance"
  [db-client {:keys [format variable benchmark_type]}]
  (let [benchmarks  (case [(empty? variable) (empty? benchmark_type)]
                        [false false] (metrics-by-variable-and-benchmark-name
                                        {:variable variable :benchmark_type benchmark_type} db-client)
                        [true  false] (metrics-by-benchmark-type
                                        {:benchmark_type benchmark_type} db-client)
                        [false  true] (metrics-by-variable-name
                                        {:variable variable} db-client)
                                      (metrics {} db-client))]
    (case format
      "csv" (csv-output benchmarks)
            (json-grouped-output field-mappings benchmarks)))) ;; Default to JSON output

