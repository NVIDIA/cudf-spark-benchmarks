
WITH sales_summary AS (
    SELECT
        c.c_customer_id,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        AVG(ss.ss_net_profit) AS avg_store_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM
        customer c
    JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE
        ss.ss_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) - 30
        AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY
        c.c_customer_id
),
web_sales_summary AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        AVG(ws.ws_net_profit) AS avg_web_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_transactions
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) - 30
        AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY
        c.c_customer_id
)
SELECT
    c.c_customer_id,
    COALESCE(ss.total_store_sales, 0) AS total_store_sales,
    COALESCE(ws.total_web_sales, 0) AS total_web_sales,
    COALESCE(ss.avg_store_profit, 0) AS avg_store_profit,
    COALESCE(ws.avg_web_profit, 0) AS avg_web_profit,
    (COALESCE(ss.total_store_sales, 0) + COALESCE(ws.total_web_sales, 0)) AS total_sales,
    (COALESCE(ss.total_transactions, 0) + COALESCE(ws.total_web_transactions, 0)) AS total_transactions
FROM
    customer c
LEFT JOIN
    sales_summary ss ON c.c_customer_id = ss.c_customer_id
LEFT JOIN
    web_sales_summary ws ON c.c_customer_id = ws.c_customer_id
WHERE
    (COALESCE(ss.total_store_sales, 0) > 1000 OR COALESCE(ws.total_web_sales, 0) > 1000)
ORDER BY
    total_sales DESC;
