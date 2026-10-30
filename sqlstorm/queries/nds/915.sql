
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.total_orders
    FROM 
        CustomerSales cs
    WHERE 
        cs.rank = 1 AND cs.total_spent > 500
),
TopItems AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    JOIN 
        HighSpenders hs ON ws.ws_ship_customer_sk = hs.c_customer_sk
    GROUP BY 
        ws.ws_item_sk
    ORDER BY 
        total_quantity DESC
    LIMIT 10
)
SELECT 
    ti.ws_item_sk,
    i.i_item_desc,
    i.i_current_price,
    ti.total_quantity,
    COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns,
    COALESCE(SUM(sr.sr_return_amt_inc_tax), 0) AS total_return_value
FROM 
    TopItems ti
JOIN 
    item i ON ti.ws_item_sk = i.i_item_sk
LEFT JOIN 
    store_returns sr ON ti.ws_item_sk = sr.sr_item_sk
GROUP BY 
    ti.ws_item_sk, i.i_item_desc, i.i_current_price, ti.total_quantity
HAVING 
    COALESCE(SUM(sr.sr_return_quantity), 0) < 5
ORDER BY 
    ti.total_quantity DESC;
