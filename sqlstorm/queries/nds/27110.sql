
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_customer_sk) AS rank_per_gender
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
benchmark_data AS (
    SELECT 
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        COUNT(cs.cs_order_number) AS total_orders,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cs.cs_sales_price) AS avg_sales_price
    FROM customer_data cd
    LEFT JOIN catalog_sales cs ON cd.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY cd.full_name, cd.ca_city, cd.ca_state, cd.ca_country
),
final_benchmark AS (
    SELECT 
        bd.*,
        ROW_NUMBER() OVER (ORDER BY bd.total_profit DESC) AS profit_rank,
        RANK() OVER (ORDER BY bd.total_orders DESC) AS order_rank
    FROM benchmark_data bd
)
SELECT 
    *,
    CASE 
        WHEN profit_rank <= 10 THEN 'Top 10 Profit'
        WHEN order_rank <= 10 THEN 'Top 10 Orders'
        ELSE 'Regular'
    END AS benchmark_category
FROM final_benchmark
WHERE total_orders > 0 AND total_profit > 0
ORDER BY total_profit DESC, total_orders DESC;
