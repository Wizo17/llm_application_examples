from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_ollama import ChatOllama
from langchain_openai import ChatOpenAI
from langchain_anthropic import ChatAnthropic
from common.llm_response import LLMResponse
from config.global_conf import global_conf


class LLMSession:
    """A class to manage Language Learning Model (LLM) sessions across different providers.

    This class provides a unified interface to interact with various LLM providers
    including OpenAI, Anthropic, Ollama, and Google. It handles the initialization
    of the appropriate LLM client based on the specified provider and model.

    Attributes:
        provider (str): The LLM provider name (openai, anthropic, ollama, or google)
        model (str): The specific model name to use with the provider
        llm: The initialized LLM client instance
        structured_llm: The LLM client configured for structured output
    """

    def __init__(self, provider=global_conf.get("LLM_PROVIDER"), model=global_conf.get("LLM_MODEL")):
        """Initialize a new LLM session.

        Args:
            provider (str, optional): The LLM provider to use. Defaults to value from global config.
            model (str, optional): The model name to use. Defaults to value from global config.

        Raises:
            Exception: If an invalid provider is specified.
        """
        self.provider = provider
        self.model = model

        OPENAI_API_KEY=global_conf.get("OPENAI_API_KEY")
        ANTHROPIC_API_KEY=global_conf.get("ANTHROPIC_API_KEY")
        GOOGLE_API_KEY=global_conf.get("GOOGLE_API_KEY")

        model_providers = {
            "openai": lambda: ChatOpenAI(model=self.model, openai_api_key=OPENAI_API_KEY),
            "anthropic": lambda: ChatAnthropic(model=self.model, anthropic_api_key=ANTHROPIC_API_KEY),
            "ollama": lambda: ChatOllama(model=self.model),
            "google": lambda: ChatGoogleGenerativeAI(model=self.model, google_api_key=GOOGLE_API_KEY),
        }

        if self.provider not in ["openai", "ollama", "anthropic", "google"]:
            raise Exception(f"Invalid LLM provider: {self.provider}")

        self.llm = model_providers[self.provider]()
        if self.provider == "google":
            self.structured_llm = self.llm.with_structured_output(LLMResponse)
        else:
            self.structured_llm = self.llm.with_structured_output(LLMResponse, method="json_mode")


    def invoke(self, message):
        """Send a message to the LLM and get a structured response.

        Args:
            message (str): The input message or prompt to send to the LLM.

        Returns:
            LLMResponse: A structured response containing the query and explanation.
        """
        return self.structured_llm.invoke(message)

