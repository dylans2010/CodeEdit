import streamlit as st
import pandas as pd
import numpy as np

st.set_page_config(page_title="{{PROJECT_NAME}}", layout="wide")

st.title("📊 {{PROJECT_NAME}} Dashboard")
st.write("Interactive analytics powered by Streamlit.")

col1, col2 = st.columns(2)
with col1:
    st.metric(label="Active Users", value="1,245", delta="+12%")
with col2:
    st.metric(label="Server Latency", value="42ms", delta="-5ms")

chart_data = pd.DataFrame(
    np.random.randn(20, 3),
    columns=['Metric A', 'Metric B', 'Metric C']
)
st.line_chart(chart_data)
