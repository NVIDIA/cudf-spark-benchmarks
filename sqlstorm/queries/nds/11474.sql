
WITH sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
customer_data AS (
    SELECT 
        c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    GROUP BY 
        c_customer_sk
)
SELECT 
    sd.ws_item_sk,
    sd.total_quantity,
    sd.total_sales,
    cd.total_orders,
    cd.total_spent,
    sd.total_profit
FROM 
    sales_data sd
JOIN 
    customer_data cd ON sd.ws_item_sk = cd.c_customer_sk
ORDER BY 
    sd.total_sales DESC
LIMIT 100;
