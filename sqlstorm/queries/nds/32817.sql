
WITH  sales_data AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_ext_sales_price,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_item_sk) as rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20230101 AND 20230331
), 
sales_summary AS (
    SELECT 
        sd.ws_order_number,
        COUNT(DISTINCT sd.ws_item_sk) AS item_count,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_ext_sales_price) AS total_sales,
        SUM(sd.ws_net_paid) AS total_net_paid
    FROM 
        sales_data sd
    GROUP BY 
        sd.ws_order_number
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        SUM(CASE WHEN cs.cs_order_number IS NOT NULL THEN cs.cs_quantity ELSE 0 END) AS total_purchases,
        AVG(cs.cs_net_paid) AS average_purchase
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
)
SELECT 
    cs.c_customer_sk,
    cs.gender,
    ss.item_count,
    ss.total_quantity,
    ss.total_sales,
    cs.total_purchases,
    cs.average_purchase,
    CASE 
        WHEN cs.gender = 'F' AND cs.total_purchases > 100 THEN 'VIP Female Customer'
        WHEN cs.gender = 'M' AND cs.total_purchases > 100 THEN 'VIP Male Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    customer_stats cs
JOIN 
    sales_summary ss ON cs.c_customer_sk IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_sold_date_sk BETWEEN 20230101 AND 20230331)
ORDER BY 
    ss.total_sales DESC
LIMIT 100;
