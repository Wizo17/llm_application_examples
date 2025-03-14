from common.llm_session import LLMSession
from common.sql_processor import SQLProcessor
from config.global_conf import global_conf

if __name__ == "__main__":
    llm_session = LLMSession()
    sql_processor = SQLProcessor()

    input_engine_folder = "sql_server"
    input_file = "05_sous_requete_having.sql"
    with open(f"sql_queries/sources/{input_engine_folder}/05_sous_requetes_complexes/{input_file}", "r") as file:
        query = file.read()

    # print(f"Base query: {query}")
    source_engine = "SQL Server"
    target_engine = "BigQuery"
    response = sql_processor.swap(llm_session, query, source_engine, target_engine)
    print(type(response))
    print(response.query)
    print(response.explanation)
    print(f"Is valid: {sql_processor.validate_syntax(response.query)}")

    output_engine_folder = "bigquery"
    with open(f"sql_queries/targets/{output_engine_folder}/{input_file}", "w") as file:
        file.write(response.query)
