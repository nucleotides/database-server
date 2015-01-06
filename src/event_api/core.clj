(ns event-api.core
  (:require [compojure.core :refer [GET defroutes]]))

(defroutes api
  (GET "/events" request str))
