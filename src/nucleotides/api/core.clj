(ns nucleotides.api.core
  (:gen-class)
  (:require [compojure.core      :refer [GET POST routes]]
            [ring.adapter.jetty  :refer [run-jetty]]

            [nucleotides.database.connection  :as con]
            [nucleotides.api.middleware       :as md]
            [nucleotides.api.benchmarks       :as benchmarks]
            [nucleotides.api.tasks            :as tasks]
            [nucleotides.api.events           :as events]))

(defn api [db]
  (-> (routes
        (GET  "/tasks/show.json"      []   (partial tasks/show        db))
        (GET  "/events/:id"           [id] (partial events/lookup     db id))
        (POST "/events"               []   (partial events/create     db))
        (GET  "/benchmarks/show.json" []   (partial benchmarks/show   db))
        (GET  "/benchmarks/:id"       [id] (partial benchmarks/lookup db id)))))

(defn -main [& args]
  (-> {:connection (con/create-connection)}
      (api)
      (md/middleware)
      (run-jetty {:port 80})))
