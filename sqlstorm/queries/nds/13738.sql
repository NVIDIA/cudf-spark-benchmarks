
WITH sales_summary AS (
    SELECT
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 2400 AND 2450
    GROUP BY
        ws_sold_date_sk
),
store_summary AS (
    SELECT
        ss_sold_date_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_net_profit
    FROM
        store_sales
    WHERE
        ss_sold_date_sk BETWEEN 2400 AND 2450
    GROUP BY
        ss_sold_date_sk
)
SELECT
    ds.d_date,
    COALESCE(ws.total_quantity, 0) AS web_sales_quantity,
    COALESCE(ws.total_net_profit, 0) AS web_sales_net_profit,
    COALESCE(ss.total_quantity, 0) AS store_sales_quantity,
    COALESCE(ss.total_net_profit, 0) AS store_sales_net_profit
FROM
    date_dim ds
LEFT JOIN
    sales_summary ws ON ds.d_date_sk = ws.ws_sold_date_sk
LEFT JOIN
    store_summary ss ON ds.d_date_sk = ss.ss_sold_date_sk
WHERE
    ds.d_date BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY
    ds.d_date;
