
WITH categorized_sales AS (
    SELECT 
        CASE 
            WHEN ws_ext_sales_price < 20 THEN 'Low'
            WHEN ws_ext_sales_price BETWEEN 20 AND 100 THEN 'Medium'
            ELSE 'High'
        END AS sales_category,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS number_of_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        sales_category
), customer_purchases AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
), high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        total_spent,
        sales_category
    FROM 
        customer_purchases cpc
    LEFT JOIN 
        categorized_sales cs ON cpc.total_spent >= 200
    JOIN 
        customer c ON c.c_customer_sk = cpc.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        total_spent > 500
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.total_spent,
    hvc.sales_category
FROM 
    high_value_customers hvc
ORDER BY 
    total_spent DESC;
