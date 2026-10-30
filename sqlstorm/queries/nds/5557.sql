
WITH CustomerMetrics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
), 
SalesOverview AS (
    SELECT 
        CASE 
            WHEN total_spent < 100 THEN 'Low Spender'
            WHEN total_spent BETWEEN 100 AND 500 THEN 'Medium Spender'
            WHEN total_spent > 500 THEN 'High Spender'
        END AS spending_category,
        COUNT(*) AS customer_count,
        AVG(total_quantity) AS avg_quantity,
        AVG(total_spent) AS avg_spent
    FROM 
        CustomerMetrics
    GROUP BY 
        spending_category
)
SELECT 
    so.spending_category,
    so.customer_count,
    so.avg_quantity,
    so.avg_spent,
    w.w_warehouse_name,
    SUM(ws.ws_ext_ship_cost) AS total_shipping_cost,
    SUM(ws.ws_net_profit) AS total_profit
FROM 
    SalesOverview so
JOIN 
    web_sales ws ON so.spending_category = CASE 
                                                WHEN ws.ws_sales_price < 100 THEN 'Low Spender'
                                                WHEN ws.ws_sales_price BETWEEN 100 AND 500 THEN 'Medium Spender'
                                                ELSE 'High Spender'
                                            END
JOIN 
    warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
GROUP BY 
    so.spending_category, so.customer_count, so.avg_quantity, so.avg_spent, w.w_warehouse_name
ORDER BY 
    so.customer_count DESC;
