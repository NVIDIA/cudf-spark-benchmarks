
WITH  sales_summary AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_paid) DESC) AS rank
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN 2450000 AND 2450630
    GROUP BY 
        cs_item_sk
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(cs.cs_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    WHERE 
        (cd.cd_gender = 'F' AND cd.cd_marital_status = 'M')
        OR (cd.cd_gender = 'M' AND cd.cd_marital_status = 'S')
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
final_summary AS (
    SELECT 
        cd.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.total_orders,
        cd.total_profit,
        s.total_quantity
    FROM 
        customer_data cd
    LEFT JOIN 
        sales_summary s ON cd.c_customer_sk = s.cs_item_sk
    WHERE 
        cd.total_orders > 0
)

SELECT 
    fs.c_customer_sk,
    fs.cd_gender,
    fs.cd_marital_status,
    fs.cd_education_status,
    COALESCE(fs.total_orders, 0) AS orders_count,
    COALESCE(fs.total_profit, 0) AS profit,
    COALESCE(fs.total_quantity, 0) AS purchased_quantity,
    CASE 
        WHEN fs.total_profit > 1000 THEN 'High Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    final_summary fs
ORDER BY 
    fs.total_profit DESC,
    fs.total_orders DESC;
