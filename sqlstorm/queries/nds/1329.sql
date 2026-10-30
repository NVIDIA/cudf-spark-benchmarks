
WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
sales_by_income AS (
    SELECT
        h.hd_income_band_sk,
        SUM(cs.total_sales) AS income_sales
    FROM
        household_demographics h
    JOIN
        customer_sales cs ON h.hd_demo_sk = cs.c_customer_sk
    GROUP BY
        h.hd_income_band_sk
),
ranked_sales AS (
    SELECT
        s.hd_income_band_sk,
        s.income_sales,
        RANK() OVER (ORDER BY s.income_sales DESC) AS income_sales_rank
    FROM
        sales_by_income s
)
SELECT
    r.hd_income_band_sk,
    r.income_sales,
    r.income_sales_rank,
    (SELECT COUNT(*)
     FROM customer c
     WHERE c.c_current_cdemo_sk IS NOT NULL AND 
           (c.c_birth_year BETWEEN 1980 AND 1990)) AS millennial_customers,
    (SELECT AVG(ws.ws_net_profit)
     FROM web_sales ws
     WHERE ws.ws_sold_date_sk IN (
         SELECT d.d_date_sk
         FROM date_dim d
         WHERE d.d_year = 2023
     )) AS avg_net_profit_2023
FROM
    ranked_sales r
WHERE
    r.income_sales > (SELECT AVG(income_sales) FROM ranked_sales)
ORDER BY
    r.income_sales_rank;
