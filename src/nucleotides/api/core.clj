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
            [nucleotides.api.events           :as events]))


;; Allows dates to be converted to JSON by liberator
(extend-type java.sql.Timestamp
  json/JSONWriter
  (-write [date out]
  (json/-write (str date) out)))


(defresource event-lookup [db id]
  :available-media-types  ["application/json"]
  :allowed-methods        [:get]
  :handle-ok              (fn [_] (events/lookup db id {})))



(defn api [db]
  (routes

    (GET  "/events/:id"           [id] (event-lookup db id))
    (POST "/events"               []   (partial events/create     db))
    (GET  "/tasks/show.json"      []   (partial tasks/show        db))
    (GET  "/tasks/:id"            [id] (partial tasks/lookup      db id))
    (GET  "/benchmarks/:id"       [id] (partial benchmarks/lookup db id))))

(defn -main [& args]
  (-> {:connection (con/create-connection)}
      (api)
      (md/middleware)
      (run-jetty {:port 80})))
