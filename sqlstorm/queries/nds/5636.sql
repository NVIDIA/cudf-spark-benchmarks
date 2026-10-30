
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY 
        ws_item_sk
),
top_items AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        ss.total_quantity_sold,
        ss.total_net_profit,
        ROW_NUMBER() OVER (ORDER BY ss.total_net_profit DESC) AS rank
    FROM 
        item i
    JOIN 
        sales_summary ss ON i.i_item_sk = ss.ws_item_sk
)
SELECT 
    t.i_item_sk,
    t.i_product_name,
    t.total_quantity_sold,
    t.total_net_profit,
    cd.cd_gender,
    cd.cd_marital_status,
    ca.ca_city,
    ca.ca_state
FROM 
    top_items t
JOIN 
    web_sales ws ON t.i_item_sk = ws.ws_item_sk
JOIN 
    customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    t.rank <= 10
ORDER BY 
    t.total_net_profit DESC;
