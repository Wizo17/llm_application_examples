# SQL Equivalence

Tool to get the sql equivalent from one engine to another.


## Build with

The project uses:
* [Python](https://www.python.org/)
* [LangChain](https://www.langchain.com/)
* [Openai API](https://platform.openai.com/)
* [Anthropic API](https://console.anthropic.com/)
* [GoogleGenerativeAI API](https://aistudio.google.com/)
* [Ollama](https://ollama.com/)


## Setup

### Prerequisites
- Python 3.8+
- pip (Python package manager)
- ollama (for local llm model)


### Installation

1. Clone this repository:
```bash
git clone https://github.com/Wizo17/llm_application_examples
cd llm_application_examples/sql_equivalent
```

2. Create a virtual environment:
```bash
python -m venv venv
```

3. Activate the virtual environment:
```bash
# Unix / MacOS
source venv/bin/activate
# Windows
venv\Scripts\activate
```

4. Install dependencies:
```bash
pip install -r requirements.txt
```
<em>If you have some issues, use python 3.12.0 and requirements_all.txt</em>


5. Create .env file:
```bash
cp .env.example .env
```

6. **Update .env file**


## Running app

```bash
streamlit run app.py
```


## Authors

* [@wizo17](https://github.com/Wizo17)

## License

This project is licensed under the ``MIT`` License - see [LICENSE](LICENSE.md) for more information.
