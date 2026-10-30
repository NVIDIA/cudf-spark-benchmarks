
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
highest_customers AS (
    SELECT 
        customer_summary.*,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM customer_summary
)
SELECT 
    h.c_first_name,
    h.c_last_name,
    h.cd_gender,
    h.cd_marital_status,
    h.cd_education_status,
    h.total_sales,
    h.total_orders,
    h.avg_net_profit
FROM highest_customers h
WHERE h.sales_rank <= 10
ORDER BY h.total_sales DESC;
