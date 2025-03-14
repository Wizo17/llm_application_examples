from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_ollama import ChatOllama
from langchain_openai import ChatOpenAI
from langchain_anthropic import ChatAnthropic
from common.llm_response import LLMResponse
from config.global_conf import global_conf


class LLMSession:
    def __init__(self, provider=global_conf.get("LLM_PROVIDER"), model=global_conf.get("LLM_MODEL")):
        self.provider = provider
        self.model = model

        model_providers = {
            "openai": lambda: ChatOpenAI(model=self.model),
            "anthropic": lambda: ChatAnthropic(model=self.model),
            "ollama": lambda: ChatOllama(model=self.model),
            "google": lambda: ChatGoogleGenerativeAI(model=self.model),
        }

        if self.provider not in ["openai", "ollama", "anthropic", "google"]:
            raise Exception(f"Invalid LLM provider: {self.provider}")

        self.llm = model_providers[self.provider]()
        self.structured_llm = self.llm.with_structured_output(LLMResponse, method="json_mode")


    def invoke(self, message):
        return self.structured_llm.invoke(message)

