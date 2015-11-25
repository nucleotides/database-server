(ns nucleotides.api.benchmarks
  (:require [yesql.core          :refer [defqueries]]
            [clojure.walk        :as walk]
            [clojure.string      :as st]
            [clojure.data.json   :as json]
            [ring.util.response  :as ring]

            [nucleotides.database.connection  :as con]
            [taoensso.timbre     :as log]))

(defqueries "nucleotides/api/benchmarks.sql")

(def long->wide
  (comp
    #(dissoc % nil)
    (partial apply hash-map)
    flatten
    (partial map vals)))


(def wide->long
  (partial map #(->> (interleave [:name :value] %)
                     (apply hash-map))))

(defn show
  "Returns all benchmarks, can be parameterised by product/evaluation completed or
  not."
  [db-client {params :params}]
  (ring/response
    ((cond
       (contains? params :evaluation) benchmarks-by-eval
       (contains? params :product)    benchmarks-by-product
       :else                          benchmarks)
     params {:connection db-client})))

(defn create
  "Creates a new benchmark event from the given parameters"
  [db-client {params :params}]
  (let [id (:id (create-benchmark-event<! params {:connection db-client}))
        {:keys [event_type success metrics]} params]
    (if (and (= event_type "evaluation") (= success "true"))
      (->> (wide->long metrics)
           (map #(assoc % :id id))
           (map #(create-metric-instance<! % {:connection (con/create-connection)}))
           (dorun))) (ring/response id)))

(defn lookup
  "Finds a benchmark instance by ID"
  [db-client id _]
  (let [metrics (->> (metrics-by-benchmark-id {:id id} {:connection db-client})
                     (long->wide)
                     (future))] ; I put this here because I wanted to experiment
                                ; with clojure futures. This may not be optimal.
   (-> (benchmark-by-id {:id id} {:connection db-client})
       (first)
       (assoc :metrics @metrics)
       (ring/response))))
