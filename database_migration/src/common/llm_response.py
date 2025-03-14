from pydantic import BaseModel, Field


class LLMResponse(BaseModel):
    query: str = Field(description="The SQL query of the BigQuery engine")
    explanation: str = Field(description="Explaining the changes made to the query")

    