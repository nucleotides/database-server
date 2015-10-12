(ns helper
  (:require [taoensso.timbre :as log]))

(defn silence-logging! []
  (log/set-config! [:appenders :standard-out :enabled? false]))
