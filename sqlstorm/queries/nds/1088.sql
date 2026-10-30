
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2453650 
    GROUP BY 
        ws.ws_item_sk
), 
customer_data AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
    GROUP BY 
        c.c_customer_sk, 
        cd.cd_marital_status, 
        cd.cd_gender, 
        cd.cd_purchase_estimate
    HAVING 
        COUNT(DISTINCT ws.ws_order_number) > 3
), 
ranked_sales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_profit,
        RANK() OVER (ORDER BY sd.total_net_profit DESC) AS profit_rank,
        RANK() OVER (ORDER BY sd.total_quantity DESC) AS quantity_rank
    FROM 
        sales_data sd
)
SELECT 
    cs.c_customer_sk,
    cs.cd_marital_status,
    cs.cd_gender,
    rs.ws_item_sk,
    rs.total_quantity,
    rs.total_net_profit,
    rs.profit_rank,
    rs.quantity_rank,
    CASE 
        WHEN cs.cd_gender = 'M' THEN 'Male'
        WHEN cs.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender_description,
    COALESCE(cs.total_orders, 0) AS total_orders
FROM 
    customer_data cs
JOIN 
    ranked_sales rs ON cs.total_orders > 0
WHERE 
    rs.total_net_profit > 5000 
    AND rs.total_quantity >= (SELECT AVG(total_quantity) FROM sales_data)
ORDER BY 
    rs.profit_rank, cs.c_customer_sk DESC
LIMIT 100;
