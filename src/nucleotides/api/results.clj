(ns nucleotides.api.results
  (:require [clojure.data.csv      :as csv]
            [yesql.core            :refer [defqueries]]
            [nucleotides.database.connection  :as con]
            [nucleotides.api.util  :as util]))

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
  (let [header (map name (keys (first data-seq)))
        out    (java.io.StringWriter.)
        write  #(csv/write-csv out (list %))]
    (write header)
    (dorun (map (comp write vals) data-seq))
    (.toString out)))


(defn complete
  "Returns metrics for each completed benchmark instance"
  [db-client response-format]
  (let [benchmarks  (completed-benchmark-metrics {} db-client)]
    (case response-format
      :json  (json-grouped-output field-mappings benchmarks)
      :csv   (csv-output benchmarks))))
