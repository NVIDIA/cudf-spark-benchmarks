
WITH ranked_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM
        customer c
        JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, ws.ws_sold_date_sk
),
address_summary AS (
    SELECT
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM
        customer_address ca
        JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
        JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE
        ca.ca_state IS NOT NULL
    GROUP BY
        ca.ca_state
),
monthly_revenue AS (
    SELECT
        d.d_year,
        SUM(ws.ws_sales_price) AS total_revenue
    FROM
        date_dim d
        JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY
        d.d_year
)
SELECT
    a.ca_state,
    a.unique_customers,
    a.avg_sales_price,
    r.total_revenue,
    s.c_first_name,
    s.c_last_name,
    s.total_quantity
FROM
    address_summary a
    LEFT JOIN monthly_revenue r ON a.unique_customers > 1000
    LEFT JOIN ranked_sales s ON a.unique_customers < 500
WHERE
    a.avg_sales_price IS NOT NULL
    AND r.total_revenue > 10000
ORDER BY
    a.unique_customers DESC,
    r.total_revenue DESC;
