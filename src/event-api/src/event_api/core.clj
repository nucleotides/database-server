(ns event-api.core
  (:require [ring.adapter.jetty :as jetty]
            [compojure.core :refer [defroutes context GET POST]]))

(defroutes events
  (GET "/events" request str))
