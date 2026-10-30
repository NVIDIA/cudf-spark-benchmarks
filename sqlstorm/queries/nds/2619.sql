
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d) 
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
), 
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM customer_sales cs
    WHERE cs.total_sales IS NOT NULL
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ib.ib_upper_bound
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)

SELECT 
    hd.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    hd.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    (CASE 
        WHEN hd.sales_rank <= 10 THEN 'Top Customer'
        WHEN hd.sales_rank <= 50 THEN 'Important Customer'
        ELSE 'Regular Customer' 
    END) AS customer_status,
    COALESCE(cd.ib_upper_bound, 0) AS upper_income_bound
FROM high_value_customers hd
JOIN customer_details cd ON hd.c_customer_sk = cd.c_customer_sk
JOIN customer c ON hd.c_customer_sk = c.c_customer_sk
ORDER BY hd.total_sales DESC, c.c_last_name
LIMIT 100;
