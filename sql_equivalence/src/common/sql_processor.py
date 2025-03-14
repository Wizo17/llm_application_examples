import re
import sqlparse
from langchain.schema import SystemMessage, HumanMessage
from templates.prompts import SYSTEM_MESSAGE, HUMAN_MESSAGE
from utils.logger import logger

class SQLProcessor:
    """A class for processing and validating SQL queries during database migration.

    This class provides functionality to validate SQL syntax and transform queries
    between different database engines using Language Learning Models (LLMs).
    It handles query validation, transformation, and error logging.
    """

    def swap(self, llm_session, sql_quey, source_engine, target_engine):
        """Transform an SQL query from one database engine format to another.

        Args:
            llm_session: An instance of LLMSession for query transformation
            sql_quey (str): The original SQL query to transform
            source_engine (str): The source database engine (e.g., 'postgresql')
            target_engine (str): The target database engine (e.g., 'mysql')

        Returns:
            LLMResponse: A structured response containing the transformed query
                        and explanation of changes
        """
        system_msg = SYSTEM_MESSAGE.format(source_engine=source_engine, target_engine=target_engine)
        human_msg = HUMAN_MESSAGE.format(source_engine=source_engine, target_engine=target_engine, query=sql_quey)
        input_messages = [
                SystemMessage(content=system_msg),
                HumanMessage(content=human_msg)
            ]
        response = llm_session.invoke(input_messages)

        return response


    def validate_syntax(self, query):
        """Validate the syntax of an SQL query using sqlparse.

        Args:
            query (str): The SQL query to validate

        Returns:
            bool: True if the query syntax is valid, False otherwise

        Logs:
            Error messages for invalid queries or parsing errors
        """
        if not isinstance(query, str) or query.strip() == "":
            logger.error("Query is None or empty.")
            return False
        
        try:
            # VALID_SQL_PATTERN = re.compile(r"^\s*(SELECT|INSERT|UPDATE|DELETE|CREATE|DROP|ALTER|WITH)\s", re.IGNORECASE)
            # if not VALID_SQL_PATTERN.match(query):
            #     logger.error(f"Invalid SQL starting statement: `{query}`")
            #     return False
            
            # Analysis with sqlparse
            parsed = sqlparse.parse(query)
            if not parsed:
                logger.error(f"SQL query `{query}` is invalid.")
                raise ValueError(f"SQL query `{query}` is invalid.")
            
            return True
        except Exception as e:
            logger.error(f"Error during syntax validation of the query {query}: {e}")
            return False
    

    def valide_query(self, query):
        """Validate an SQL query's syntax.

        Args:
            query (str): The SQL query to validate

        Returns:
            bool: True if the query is valid, False otherwise
        """
        return self.validate_syntax(query)
    