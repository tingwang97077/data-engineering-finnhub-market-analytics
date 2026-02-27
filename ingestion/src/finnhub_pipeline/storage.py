"""Parquet export helpers for GCS."""

from __future__ import annotations

from io import BytesIO

import pandas as pd
from google.cloud import storage


class GCSParquetSink:
    def __init__(self, project_id: str, bucket_name: str):
        self.client = storage.Client(project=project_id)
        self.bucket = self.client.bucket(bucket_name)

    def write_dataframe(self, dataframe: pd.DataFrame, object_path: str) -> None:
        if dataframe.empty:
            return

        buf = BytesIO()
        dataframe.to_parquet(buf, engine="pyarrow", index=False)
        buf.seek(0)

        blob = self.bucket.blob(object_path)
        blob.upload_from_file(buf, content_type="application/octet-stream")
