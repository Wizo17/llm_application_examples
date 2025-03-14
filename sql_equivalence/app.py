import sys
import os

# Add the src directory to Python path for module imports
sys.path.append(os.path.dirname(os.path.abspath(__file__)) + "/src")

# Import required libraries and custom modules
import streamlit as st
from src.common.llm_session import LLMSession
from src.common.sql_processor import SQLProcessor
from src.utils.logger import logger

# Set up the main title of the Streamlit application
st.title('Database Migration GUI Example')

# Create a form for user inputs
with st.form("my_form"):
    # Create a 3-column layout for input parameters
    cols = st.columns(3)
    # Dropdown for LLM model selection with default to gemini-2.0-flash (index 4)
    f_model = cols[0].selectbox("LLM Model:", ["gpt-4o-mini", "claude-3-5-sonnet-latest", "claude-3-7-sonnet-latest", "gemini-1.5-pro", "gemini-2.0-flash"], 4)
    # Dropdown for source database engine selection
    f_source_engine = cols[1].selectbox("DB Engine Source:", ["SQL Server", "SAP BO"], 0)
    # Dropdown for target database engine selection
    f_target_engine = cols[2].selectbox("DB Engine Traget:", ["BigQuery"], 0)

    # Text area for SQL query input
    f_query = st.text_area("Enter your query")
    # Form submission button
    submit = st.form_submit_button("Process")

# Handle form submission
if submit:
    # Validate all required inputs
    f_valid = True
    if f_model is None:
        st.error("Please select the LLM Model")
        f_valid = False
    if f_source_engine is None:
        st.error("Please select the Source Engine")
        f_valid = False
    if f_target_engine is None:
        st.error("Please select the Target Engine")
        f_valid = False
    if f_query == "":
        st.error("Please enter a query")
        f_valid = False

    # Process the query if all inputs are valid
    if f_valid:
        # Determine the LLM provider based on the selected model
        if f_model in ["gpt-4o-mini", "gpt-4o-turbo"]:
            provider = "openai"
        elif f_model in ["claude-3-5-sonnet-latest", "claude-3-7-sonnet-latest"]:
            provider = "anthropic"
        elif f_model in ["gemini-1.5-pro", "gemini-2.0-flash"]:
            provider = "google"
        else:
            provider = "ollama"
        
        try:
            # Initialize SQL processor and validate the input query
            sql_processor = SQLProcessor()
            if sql_processor.valide_query(f_query):
                # Create LLM session and process the query transformation
                llm_session = LLMSession(provider=provider, model=f_model)
                response = sql_processor.swap(llm_session, f_query, f_source_engine, f_target_engine)

                # Handle empty response case
                if response.query is None:
                    query = ""
                else:
                    query = response.query

                # Display results
                st.write(f"Is valid: {sql_processor.valide_query(response.query)}")
                st.code(query, language="sql")
                st.markdown(response.explanation)
            else:
                st.error("Invalid base SQL query")
        except Exception as e:
            # Display any errors that occur during processing
            st.error(f"Error: {e}")


