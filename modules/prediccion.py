"""
prediccion.py
-------------
Modelo de predicción de ventas basado en GradientBoosting.

Como las fechas del CSV están corruptas, se usa el id_pedido
como proxy temporal (IDs más altos = pedidos más recientes).

El modelo predice el ticket promedio del próximo bloque de N pedidos.

Uso
---
    from modules.prediccion import PredictorVentas

    predictor = PredictorVentas()
    predictor.entrenar(orders_mx)              # entrena
    resultado = predictor.predecir(n_bloques=5)
    predictor.guardar("models/predictor.pkl")  # persiste el modelo
    predictor.cargar("models/predictor.pkl")   # carga modelo existente
"""

import os
import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.preprocessing import RobustScaler
from sklearn.metrics import mean_absolute_error, mean_absolute_percentage_error


FEATURES = [
    "orden_temporal",
    "rolling_mean_100",
    "rolling_std_100",
    "rolling_max_100",
    "rolling_min_100",
    "lag_1",
    "lag_5",
    "lag_10",
    "lag_50",
    "tendencia_local",
    "valor_pedido",
    "SubTotal",
    "cedis",
]

WINDOW = 100   # ventana de rolling features
BLOQUE = 50    # tamaño del bloque de predicción (N pedidos)


class PredictorVentas:
    """
    Predice el ticket promedio del próximo bloque de pedidos.

    Atributos públicos después de entrenar
    ----------------------------------------
    mae       : error absoluto promedio en el set de prueba
    mape      : error porcentual promedio en el set de prueba
    feature_importances : dict {feature: importancia}
    """

    def __init__(self, bloque: int = BLOQUE):
        self.bloque    = bloque
        self.modelo    = GradientBoostingRegressor(
            n_estimators=300,
            learning_rate=0.05,
            max_depth=5,
            subsample=0.8,
            random_state=42,
        )
        self.scaler    = RobustScaler()
        self.mae       = None
        self.mape      = None
        self.feature_importances = {}
        self._df_features = None   # guardamos para predecir después

    # ── Entrenamiento ─────────────────────────────────────

    def entrenar(self, orders_mx: pd.DataFrame) -> dict:
        """
        Entrena el modelo con los pedidos entregados de México.

        Parámetros
        ----------
        orders_mx : DataFrame de data_loader.cargar_datos()

        Retorna
        -------
        dict con mae, mape y feature_importances
        """
        df = self._preparar_features(orders_mx)
        self._df_features = df   # guardamos para predicciones futuras

        X = df[FEATURES]
        y = df["target"]

        split = int(len(df) * 0.8)
        X_train, X_test = X.iloc[:split], X.iloc[split:]
        y_train, y_test = y.iloc[:split], y.iloc[split:]

        X_train_s = self.scaler.fit_transform(X_train)
        X_test_s  = self.scaler.transform(X_test)

        self.modelo.fit(X_train_s, y_train)

        y_pred    = self.modelo.predict(X_test_s)
        self.mae  = round(mean_absolute_error(y_test, y_pred), 2)
        self.mape = round(mean_absolute_percentage_error(y_test, y_pred) * 100, 1)

        self.feature_importances = dict(
            zip(FEATURES, self.modelo.feature_importances_.tolist())
        )

        return {
            "mae":  self.mae,
            "mape": self.mape,
            "feature_importances": self.feature_importances,
            "train_n": len(X_train),
            "test_n":  len(X_test),
        }

    # ── Predicción ────────────────────────────────────────

    def predecir(self, n_bloques: int = 5) -> dict:
        """
        Predice el ticket promedio de los próximos n_bloques.

        Retorna
        -------
        dict con lista de predicciones y venta total estimada por bloque
        """
        if self._df_features is None:
            raise RuntimeError("Llama a entrenar() antes de predecir().")

        last_rows  = self._df_features[FEATURES].iloc[-n_bloques:]
        last_scaled = self.scaler.transform(last_rows)
        preds       = self.modelo.predict(last_scaled)

        bloques = []
        for i, p in enumerate(preds, 1):
            bloques.append({
                "bloque":          i,
                "ticket_promedio": round(float(p), 2),
                "venta_estimada":  round(float(p) * self.bloque, 2),
            })

        return {
            "bloques":     bloques,
            "n_pedidos_por_bloque": self.bloque,
            "mae":         self.mae,
            "mape":        self.mape,
        }

    # ── Persistencia ──────────────────────────────────────

    def guardar(self, path: str):
        """Guarda el modelo entrenado en disco."""
        os.makedirs(os.path.dirname(path), exist_ok=True)
        joblib.dump({
            "modelo":       self.modelo,
            "scaler":       self.scaler,
            "df_features":  self._df_features,
            "mae":          self.mae,
            "mape":         self.mape,
            "importances":  self.feature_importances,
            "bloque":       self.bloque,
        }, path)
        print(f"Modelo guardado en {path}")

    def cargar(self, path: str):
        """Carga un modelo previamente entrenado."""
        data = joblib.load(path)
        self.modelo               = data["modelo"]
        self.scaler               = data["scaler"]
        self._df_features         = data["df_features"]
        self.mae                  = data["mae"]
        self.mape                 = data["mape"]
        self.feature_importances  = data["importances"]
        self.bloque               = data["bloque"]
        print(f"Modelo cargado desde {path}")

    # ── Feature engineering (privado) ────────────────────

    def _preparar_features(self, orders_mx: pd.DataFrame) -> pd.DataFrame:
        entregados = orders_mx[orders_mx["status_final"] == "Entregado"].copy()
        entregados = entregados.sort_values("id_pedido_num").reset_index(drop=True)
        entregados["orden_temporal"] = range(len(entregados))

        df = entregados[[
            "orden_temporal", "Total", "valor_pedido", "SubTotal", "cedis"
        ]].copy()
        df["cedis"] = df["cedis"].fillna(0)

        df["rolling_mean_100"] = df["Total"].rolling(WINDOW, min_periods=10).mean()
        df["rolling_std_100"]  = df["Total"].rolling(WINDOW, min_periods=10).std()
        df["rolling_max_100"]  = df["Total"].rolling(WINDOW, min_periods=10).max()
        df["rolling_min_100"]  = df["Total"].rolling(WINDOW, min_periods=10).min()
        df["lag_1"]            = df["Total"].shift(1)
        df["lag_5"]            = df["Total"].shift(5)
        df["lag_10"]           = df["Total"].shift(10)
        df["lag_50"]           = df["Total"].shift(50)
        df["tendencia_local"]  = df["Total"].rolling(50, min_periods=5).mean().diff(10)

        # Target: promedio del siguiente bloque de N pedidos
        df["target"] = df["Total"].rolling(self.bloque).mean().shift(-self.bloque)

        return df.dropna().copy()
