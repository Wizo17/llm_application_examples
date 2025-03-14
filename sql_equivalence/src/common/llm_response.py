from pydantic import BaseModel, Field


class LLMResponse(BaseModel):
    """A data model representing the response from a Language Learning Model (LLM).
    
    This class encapsulates the output from LLM processing, specifically for SQL query
    transformations and their explanations. It includes both the transformed query and
    a detailed explanation of the changes made during the transformation process.
    """
    
    query: str | None = Field(default=None, description="The SQL query of the target engine")
    explanation: str = Field(description="Explaining the changes made to the query")
