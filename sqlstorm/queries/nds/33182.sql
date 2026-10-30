
WITH  sales_summary AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (
            SELECT 
                MAX(d_date_sk) 
            FROM 
                date_dim 
            WHERE 
                d_year = 2022
        )
    GROUP BY 
        ws_bill_customer_sk
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_profit,
        cs.total_orders
    FROM 
        customer c
    JOIN 
        sales_summary cs ON c.c_customer_sk = cs.ws_bill_customer_sk
    WHERE 
        cs.profit_rank <= 100
),
inventory_stats AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        AVG(inv.inv_quantity_on_hand) AS avg_quantity
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
item_information AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        inv.total_quantity,
        inv.avg_quantity,
        CASE 
            WHEN inv.total_quantity IS NULL THEN 'Out of Stock'
            ELSE 'In Stock'
        END AS stock_status
    FROM 
        item i
    LEFT JOIN 
        inventory_stats inv ON i.i_item_sk = inv.inv_item_sk
)
SELECT 
    c.c_customer_sk AS c_customer_id,
    c.c_first_name,
    c.c_last_name,
    item.i_item_desc,
    item.i_current_price,
    item.stock_status,
    SUM(ws.ws_net_profit) AS total_profit_contributed,
    COUNT(ws.ws_order_number) AS total_orders_placed
FROM 
    high_value_customers c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item_information item ON ws.ws_item_sk = item.i_item_sk
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, item.i_item_desc, item.i_current_price, item.stock_status
ORDER BY 
    total_profit_contributed DESC
LIMIT 50;
