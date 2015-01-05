(ns event-api.core
  (:require [compojure.core :refer [GET defroutes]]))

(defroutes events
  (GET "/events" request str))
