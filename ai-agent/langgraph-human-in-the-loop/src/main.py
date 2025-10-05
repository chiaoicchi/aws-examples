import uuid

import streamlit as st
from langchain_core.messages import HumanMessage
from langchain_core.runnables import RunnableConfig
from langgraph.types import Command

from agent import agent


def init_session_state():
    """
    Initialize session state
    """
    if "messages" not in st.session_state:
        st.session_state.messages = []
    if "waiting_for_approval" not in st.session_state:
        st.session_state.waiting_for_approval = False
    if "final_result" not in st.session_state:
        st.session_state.final_result = None
    if "thread_id" not in st.session_state:
        st.session_state.thread_id = None


def reset_session():
    """
    Reset session state
    """
    st.session_state.messages = []
    st.session_state.waiting_for_approval = False
    st.session_state.final_result = None
    st.session_state.thread_id = None


init_session_state()


def run_agent(input_data):
    """
    Execute agent and process result
    """
    config = RunnableConfig(
        configurable={
            "thread_id": st.session_state.thread_id,
        },
    )

    with st.spinner("processing ...", show_time=True):
        for chunk in agent.stream(input_data, stream_mode="updates", config=config):
            for task_name, result in chunk.items():
                if task_name == "__interrupt__":
                    st.session_state.tool_info = result[0].value
                    st.session_state.waiting_for_approval = True

                elif task_name == "agent":
                    st.session_state.final_result = result.content

                elif task_name == "invoke_llm":
                    if isinstance(chunk["invoke_llm"].content, list):
                        for content in result.content:
                            if content["type"] == "text":
                                st.session_state.messages.append(
                                    {"role": "assistant", "content": content["text"]}
                                )

                elif task_name == "use_tool":
                    st.session_state.messages.append(
                        {"role": "assistant", "content": "execute tools"}
                    )
        st.rerun()


def feedback():
    """
    Get feedback and send it to agent
    """
    approve_column, deny_column = st.columns(2)

    feedback_result = None
    with approve_column:
        if st.button("APPROVE", width="stretch"):
            st.session_state.waiting_for_approval = False
            feedback_result = "APPROVE"
    with deny_column:
        if st.button("DENY", width="stretch"):
            st.session_state.waiting_for_approval = False
            feedback_result = "DENY"

    return feedback_result


def app():
    st.title("Web research agent")

    # Show messages
    for msg in st.session_state.messages:
        if msg["role"] == "user":
            st.chat_message("user").write(msg["content"])
        else:
            st.chat_message("assistant").write(msg["content"])

    # Approve tool use
    if st.session_state.waiting_for_approval and st.session_state.tool_info:
        st.info(st.session_state.tool_info["args"])
        if st.session_state.tool_info["name"] == "write_file":
            with st.container(height=400):
                st.html(st.session_state.tool_info["html"], width="stretch")
        feedback_result = feedback()
        if feedback_result:
            st.chat_message("user").write(feedback_result)
            st.session_state.messages.append(
                {"role": "user", "content": feedback_result}
            )
            run_agent(Command(resume=feedback_result))
            st.rerun()

    # Show result
    if st.session_state.final_result and not st.session_state.waiting_for_approval:
        st.subheader("Result")
        st.success(st.session_state.final_result)

    # User input area
    if not st.session_state.waiting_for_approval:
        user_input = st.chat_input("Write message")
        if user_input:
            reset_session()
            st.session_state.thread_id = str(uuid.uuid4())
            st.chat_message("user").write(user_input)
            st.session_state.messages.append({"role": "user", "content": user_input})

            messages = [HumanMessage(content=user_input)]
            if run_agent(messages):
                st.rerun()
    else:
        st.info("Wait for tool use approved.")


if __name__ == "__main__":
    app()
