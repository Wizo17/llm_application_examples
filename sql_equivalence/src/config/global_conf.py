import os
from dotenv import load_dotenv
from typing import Any, Dict
from utils.logger import logger

class Configuration:
    """
    Configuration is a singleton class responsible for loading and providing access
    to the application's configuration settings from environment variables.
    """
    _instance = None
    _config: Dict[str, Any] = None

    def __new__(cls):
        """
        Create a new instance of the Configuration class if one does not already exist.

        Returns:
            Configuration: The singleton instance of the Configuration class.
        """
        if cls._instance is None:
            cls._instance = super(Configuration, cls).__new__(cls)
            cls._instance._initialize()
        return cls._instance

    def _initialize(self):
        """
        Initialize the Configuration instance by loading environment variables
        and storing them in a dictionary.
        """
        load_dotenv()
        
        self._config = {
            "LLM_PROVIDER": os.getenv("LLM_PROVIDER"),
            "LLM_MODEL": os.getenv("LLM_MODEL"),

            "OPENAI_API_KEY": os.getenv("OPENAI_API_KEY"),
            "ANTHROPIC_API_KEY": os.getenv("ANTHROPIC_API_KEY"),
            "GOOGLE_API_KEY": os.getenv("GOOGLE_API_KEY"),
        }

    def get(self, key: str) -> Any:
        """
        Get the value of a configuration setting by key.

        Args:
            key (str): The key of the configuration setting.

        Returns:
            Any: The value of the configuration setting, or an empty string if the key is not found.
        """
        try:
            return self._config[key]
        except (KeyError, ValueError) as e:
            logger.error(f"Invalid configuration key: {key}")
            return ""


# Create a single instance for import
global_conf = Configuration()