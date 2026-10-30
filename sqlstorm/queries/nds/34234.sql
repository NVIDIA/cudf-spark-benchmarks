WITH  sales_summary AS (
    SELECT
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 0
    GROUP BY ws.ws_sold_date_sk
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS customer_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE cd.cd_marital_status = 'M'
)
SELECT 
    s.ws_sold_date_sk,
    s.total_sales,
    s.order_count,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_purchase_estimate
FROM sales_summary s
LEFT JOIN customer_details cd ON s.ws_sold_date_sk = cd.d_year
WHERE s.total_sales > (SELECT AVG(total_sales) FROM sales_summary)
ORDER BY s.ws_sold_date_sk DESC, s.total_sales DESC
LIMIT 100;