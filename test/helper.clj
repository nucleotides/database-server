(ns helper
  (:require [clojure.java.jdbc               :as sql]
            [clojure.string                  :as string]
            [taoensso.timbre                 :as log]
            [migratus.core                   :as mg]
            [nucleotides.database.migrate    :as build]
            [nucleotides.database.connection :as con]))

(log/set-config! [:appenders :standard-out :enabled? false])
