
WITH sales_summary AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        d.d_quarter_seq,
        ca.ca_state,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_revenue,
        AVG(ws.ws_net_paid) AS average_order_value
    FROM
        date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY
        d.d_year, d.d_month_seq, d.d_quarter_seq, ca.ca_state
),
top_states AS (
    SELECT
        ca_state,
        SUM(total_revenue) AS state_revenue
    FROM
        sales_summary
    GROUP BY
        ca_state
    ORDER BY
        state_revenue DESC
    LIMIT 5
),
performance_metrics AS (
    SELECT
        ss.d_year,
        ss.d_month_seq,
        ss.d_quarter_seq,
        ss.ca_state,
        ss.total_quantity_sold,
        ss.total_revenue,
        ss.average_order_value,
        ts.state_revenue
    FROM
        sales_summary ss
    JOIN top_states ts ON ss.ca_state = ts.ca_state
)
SELECT
    d_year,
    d_month_seq,
    d_quarter_seq,
    ca_state,
    total_quantity_sold,
    total_revenue,
    average_order_value,
    state_revenue,
    (total_revenue / NULLIF(total_quantity_sold, 0)) AS revenue_per_unit
FROM
    performance_metrics
ORDER BY
    d_year DESC, d_month_seq DESC, total_revenue DESC;
