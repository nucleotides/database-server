(ns nucleotides.api.core
  (:gen-class)
  (:require [compojure.core           :refer [GET POST routes]]
            [liberator.core           :refer [defresource]]
            [liberator.representation :refer [ring-response]]

            [ring.adapter.jetty  :refer [run-jetty]]

            [clojure.data.json                :as json]
            [nucleotides.database.connection  :as con]
            [nucleotides.api.middleware       :as md]
            [nucleotides.api.status           :as status]
            [nucleotides.api.benchmarks       :as benchmarks]
            [nucleotides.api.tasks            :as tasks]
            [nucleotides.api.events           :as events]
            [nucleotides.api.results          :as results]))

(def content-types
  {:json "application/json;charset=UTF-8", :csv "text/csv;charset=UTF-8"})


;; Allows dates to be converted to JSON by liberator
(extend-type java.sql.Timestamp
  json/JSONWriter
  (-write [date out]
  (json/-write (str date) out)))

(def request-body
  #(get-in % [:request :body]))

(defresource event-lookup [db id]
  :available-media-types  ["application/json"]
  :allowed-methods        [:get]
  :exists?                (fn [_] (events/exists? id))
  :handle-not-found       (fn [_] (str "Event not found: " id))
  :handle-ok              (fn [_] (events/lookup db id {})))

(defresource event-create [db]
  :available-media-types        ["application/json"]
  :allowed-methods              [:post]
  :processable?                 (comp events/valid? request-body)
  :handle-unprocessable-entity  (comp events/error-message request-body)
  :post!                        (comp #(hash-map ::id %) (partial events/create db) request-body)
  :location                     (fn [ctx] (format "/events/%s" (::id ctx))))

(defresource benchmark [db id]
  :available-media-types  ["application/json"]
  :allowed-methods        [:get]
  :exists?                (fn [_] (benchmarks/exists? id))
  :handle-not-found       (fn [_] (str "Benchmark not found: " id))
  :handle-ok              (fn [_] (benchmarks/lookup db id {})))

(defresource task-show [db]
  :available-media-types  ["application/json"]
  :allowed-methods        [:get]
  :handle-ok              (fn [_] (tasks/show db {})))

(defresource task-lookup [db id]
  :available-media-types  ["application/json"]
  :allowed-methods        [:get]
  :exists?                (fn [_] (tasks/exists? id))
  :handle-not-found       (fn [_] (str "Task not found: " id))
  :handle-ok              (fn [_] (tasks/lookup db id {})))

(defresource results-complete [db]
  :available-media-types  ["application/json" "text/csv"]
  :allowed-methods        [:get]
  :handle-ok              (fn [request]
                            (let [params          (get-in request [:request :params])
                                  response-format (keyword (:format params))
                                  disposition     (str "attachment; filename=\"nucleotides_benchmark_metrics." (name response-format) "\"")
                                  response        {:headers {"Content-Type" (content-types response-format)
                                                             "Content-Disposition" disposition}
                                                   :body    (results/complete db response-format params)}]
                              (ring-response response))))

(defresource status-show [db]
  :available-media-types  ["application/json"]
  :allowed-methods        [:get]
  :handle-ok              (fn [_] (status/show db)))


(defn api [db]
  (routes
    (GET  "/status.json"            []   (status-show db))
    (GET  "/events/:id"             [id] (event-lookup db id))
    (POST "/events"                 []   (event-create db))
    (GET  "/benchmarks/:id"         [id] (benchmark db id))
    (GET  "/tasks/show.json"        []   (task-show db))
    (GET  "/tasks/:id"              [id] (task-lookup db id))
    (GET  "/results/complete"       []   (results-complete db))))

(defn -main [& _]
  (-> {:connection (con/create-connection)}
      (api)
      (md/middleware)
      (run-jetty {:port 80})))
