
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreSales AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(ss.ss_ticket_number) AS total_store_orders
    FROM
        store s
    JOIN
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY
        s.s_store_sk, s.s_store_name
),
SalesComparison AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        COALESCE(cs.total_web_sales, 0) AS web_sales,
        COALESCE(ss.total_store_sales, 0) AS store_sales,
        CASE
            WHEN COALESCE(cs.total_web_sales, 0) > COALESCE(ss.total_store_sales, 0) THEN 'Web'
            WHEN COALESCE(cs.total_web_sales, 0) < COALESCE(ss.total_store_sales, 0) THEN 'Store'
            ELSE 'Equal'
        END AS preferred_channel
    FROM
        CustomerSales cs
    FULL OUTER JOIN
        StoreSales ss ON cs.c_customer_sk = ss.s_store_sk
)
SELECT
    preferred_channel,
    COUNT(*) AS num_customers,
    AVG(web_sales) AS avg_web_sales,
    AVG(store_sales) AS avg_store_sales
FROM
    SalesComparison
GROUP BY
    preferred_channel
ORDER BY
    num_customers DESC;
