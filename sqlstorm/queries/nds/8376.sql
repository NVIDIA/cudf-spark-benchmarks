WITH Summary AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 1998 AND 2001  
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
),
RankedSummary AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM
        Summary
)
SELECT
    *,
    CASE 
        WHEN sales_rank <= 10 THEN 'Top 10 Customer'
        ELSE 'Other'
    END AS customer_category
FROM
    RankedSummary
WHERE
    total_sales > 1000
ORDER BY
    d_year, total_sales DESC;