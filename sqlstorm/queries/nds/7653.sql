
WITH ranked_sales AS (
    SELECT
        ws_ship_date_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        RANK() OVER (PARTITION BY ws_ship_date_sk ORDER BY SUM(ws_sales_price * ws_quantity) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_ship_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
                              AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY ws_ship_date_sk
),
top_sales AS (
    SELECT
        d.d_date,
        rs.total_sales
    FROM ranked_sales rs
    JOIN date_dim d ON rs.ws_ship_date_sk = d.d_date_sk
    WHERE rs.sales_rank <= 10
)
SELECT 
    d.d_year,
    COUNT(ts.total_sales) AS num_of_top_sales_days,
    AVG(ts.total_sales) AS avg_sales_per_day
FROM top_sales ts
JOIN date_dim d ON ts.d_date = d.d_date
GROUP BY d.d_year
ORDER BY d.d_year;
