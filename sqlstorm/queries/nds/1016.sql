
WITH customer_sales AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders
    FROM
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY
        c.c_customer_id
),
store_sales AS (
    SELECT
        c.c_customer_id,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM
        customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE
        c.c_current_addr_sk IS NOT NULL
    GROUP BY
        c.c_customer_id
),
sales_summary AS (
    SELECT
        cs.c_customer_id,
        COALESCE(cs.total_web_sales, 0) AS web_sales,
        COALESCE(ss.total_store_sales, 0) AS store_sales
    FROM
        customer_sales cs
    FULL OUTER JOIN store_sales ss ON cs.c_customer_id = ss.c_customer_id
),
ranked_sales AS (
    SELECT
        s.c_customer_id,
        s.web_sales + s.store_sales AS total_sales,
        RANK() OVER (ORDER BY s.web_sales + s.store_sales DESC) AS sales_rank
    FROM
        sales_summary s
)
SELECT
    r.sales_rank,
    r.c_customer_id,
    r.total_sales,
    CASE
        WHEN r.total_sales = 0 THEN 'No Sales'
        WHEN r.total_sales < 100 THEN 'Low Sales'
        WHEN r.total_sales < 1000 THEN 'Medium Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM
    ranked_sales r
WHERE
    r.sales_rank <= 10
ORDER BY
    r.sales_rank;
