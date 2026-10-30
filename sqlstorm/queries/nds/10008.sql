
WITH sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
customer_data AS (
    SELECT 
        c_customer_sk,
        COUNT(DISTINCT cd_demo_sk) AS demo_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        c_customer_sk
)
SELECT 
    sd.ws_item_sk,
    sd.total_sales,
    sd.total_orders,
    cd.demo_count,
    cd.avg_purchase_estimate
FROM 
    sales_data sd
JOIN 
    customer_data cd ON sd.ws_item_sk = cd.c_customer_sk
ORDER BY 
    sd.total_sales DESC
LIMIT 100;
