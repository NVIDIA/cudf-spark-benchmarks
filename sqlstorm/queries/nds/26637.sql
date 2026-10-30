
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(CASE WHEN ws.ws_sales_price IS NOT NULL THEN ws.ws_sales_price ELSE 0 END) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_ship_date_sk) AS distinct_ship_days
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
AggregatedStats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(DISTINCT c_customer_id) AS total_customers,
        AVG(total_spent) AS avg_spent,
        AVG(order_count) AS avg_orders,
        AVG(distinct_ship_days) AS avg_distinct_ship_days
    FROM 
        CustomerStats
    GROUP BY 
        cd_gender, cd_marital_status, cd_education_status
)
SELECT 
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_customers,
    avg_spent,
    avg_orders,
    avg_distinct_ship_days,
    CONCAT('Total customers: ', total_customers, ', Avg spent: $', ROUND(avg_spent, 2), ', Avg orders: ', ROUND(avg_orders, 2), ', Avg distinct ship days: ', ROUND(avg_distinct_ship_days, 2)) AS summary_description 
FROM 
    AggregatedStats
ORDER BY 
    avg_spent DESC;
