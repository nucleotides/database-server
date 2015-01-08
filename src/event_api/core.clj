(ns event-api.core
  (:require [compojure.core :refer [GET POST defroutes]]))

(defn post-event
  "Process a post event request. Return 202 if
  valid otherwise return appropriate HTTP error
  code otherwise."
  [request]
  {:status 422})

(defroutes api
  (POST "/events" request post-event))
