
WITH sales_summary AS (
    SELECT
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        ws.ws_sold_date_sk
),
customer_summary AS (
    SELECT
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_marital_status = 'M'
    GROUP BY
        cd.cd_gender
),
store_summary AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        SUM(ss.ss_quantity) AS total_store_sales,
        SUM(ss.ss_net_profit) AS total_store_profit
    FROM
        store s
    JOIN
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY
        s.s_store_id, s.s_store_name
)
SELECT
    ss.ws_sold_date_sk,
    ss.total_quantity_sold,
    ss.total_net_profit,
    cs.cd_gender,
    cs.total_customers,
    cs.avg_purchase_estimate,
    st.s_store_id,
    st.total_store_sales,
    st.total_store_profit
FROM
    sales_summary ss
JOIN
    customer_summary cs ON cs.total_customers IS NOT NULL
JOIN
    store_summary st ON st.total_store_sales IS NOT NULL
ORDER BY
    ss.ws_sold_date_sk DESC, cs.cd_gender, st.total_store_profit DESC;
