import json
import pandas as pd
from pydantic import ValidationError

class Validator:
    @staticmethod
    def validate(df, model):
        def _validate(payload):
            try:
                model.model_validate_json(payload)
                return True, "success"
            except ValidationError as e:
                return False, str(e)
            except Exception as e:
                return False, str(e)

        results = df["payload"].apply(_validate)
        df["valid"] = results.apply(lambda x: x[0])
        df["details"] = results.apply(lambda x: x[1])
        return df
