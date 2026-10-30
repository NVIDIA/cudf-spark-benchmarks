
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_sales_price) AS average_sales_price,
        MIN(ws.ws_sold_date_sk) AS first_sale_date,
        MAX(ws.ws_sold_date_sk) AS last_sale_date,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F'
        AND i.i_current_price > 50.00
    GROUP BY 
        ws.ws_item_sk
    HAVING 
        SUM(ws.ws_quantity) > 100
),
average_profit AS (
    SELECT 
        AVG(total_net_profit) AS avg_profit
    FROM 
        sales_summary
),
high_sales_items AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity_sold,
        s.total_net_profit,
        p.p_promo_name
    FROM 
        sales_summary s
    JOIN 
        promotion p ON s.ws_item_sk = p.p_item_sk
    WHERE 
        s.total_net_profit > (SELECT avg_profit FROM average_profit)
)
SELECT 
    hi.ws_item_sk,
    hi.total_quantity_sold,
    hi.total_net_profit,
    hi.p_promo_name
FROM 
    high_sales_items hi
JOIN 
    item i ON hi.ws_item_sk = i.i_item_sk
ORDER BY 
    hi.total_net_profit DESC
LIMIT 10;
