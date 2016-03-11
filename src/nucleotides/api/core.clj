(ns nucleotides.api.core
  (:gen-class)
  (:require [compojure.core  :refer [GET POST routes]]
            [liberator.core  :refer [defresource]]

            [ring.adapter.jetty  :refer [run-jetty]]

            [clojure.data.json                :as json]

            [nucleotides.database.connection  :as con]
            [nucleotides.api.middleware       :as md]
            [nucleotides.api.benchmarks       :as benchmarks]
            [nucleotides.api.tasks            :as tasks]
            [nucleotides.api.metrics          :as metrics]
            [nucleotides.api.events           :as events]))


;; Allows dates to be converted to JSON by liberator
(extend-type java.sql.Timestamp
  json/JSONWriter
  (-write [date out]
  (json/-write (str date) out)))


(defresource event-lookup [db id]
  :available-media-types  ["application/json"]
  :allowed-methods        [:get]
  :exists?                (fn [_] (events/exists? id))
  :handle-not-found       (fn [_] (str "Event not found: " id))
  :handle-ok              (fn [_] (events/lookup db id {})))

(defresource event-create [db]
  :available-media-types        ["application/json"]
  :allowed-methods              [:post]
  :processable?                 (fn [ctx] (->> (get-in ctx [:request :body])
                                               (events/valid?)))
  :handle-unprocessable-entity  (fn [ctx]
                                  (->> (get-in ctx [:request :body])
                                       (events/error-message)))

  :post!                        #(events/create db (get-in % [:request :body]))
  :location                     (fn [ctx] {:location (format "/events/%s" (::id ctx))}))

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


(defn api [db]
  (routes

    (GET  "/events/:id"           [id] (event-lookup db id))
    (POST "/events"               []   (event-create db))
    (GET  "/benchmarks/:id"       [id] (benchmark db id))
    (GET  "/tasks/show.json"      []   (task-show db))
    (GET  "/tasks/:id"            [id] (task-lookup db id))))

(defn -main [& args]
  (-> {:connection (con/create-connection)}
      (api)
      (md/middleware)
      (run-jetty {:port 80})))
