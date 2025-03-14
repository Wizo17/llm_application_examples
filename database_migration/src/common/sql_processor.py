import sqlparse
from langchain.schema import SystemMessage, HumanMessage
from templates.prompts import SYSTEM_MESSAGE, HUMAN_MESSAGE
from utils.logger import logger

class SQLProcessor:

    def swap(self, llm_session, sql_quey, source_engine, target_engine):
        system_msg = SYSTEM_MESSAGE.format(source_engine=source_engine, target_engine=target_engine)
        human_msg = HUMAN_MESSAGE.format(source_engine=source_engine, target_engine=target_engine, query=sql_quey)
        input_messages = [
                SystemMessage(content=system_msg),
                HumanMessage(content=human_msg)
            ]
        response = llm_session.invoke(input_messages)

        return response

    def validate_syntax(self, query):
        """
        Validate the syntax of the SQL query.

        Args:
            query (str): The SQL query to be validated.

        Returns:
            bool: True if the syntax is valid, False otherwise.
        """
        try:
            # Analysis with sqlparse
            parsed = sqlparse.parse(query)
            if not parsed:
                logger.error(f"SQL query `{query}` is invalid.")
                raise ValueError(f"SQL query `{query}` is invalid.")
            
            return True
        except Exception as e:
            logger.error(f"Error during syntax validation of the query {query}: {e}")
            return False