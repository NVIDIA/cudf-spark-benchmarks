
WITH TopItems AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        i.i_item_id
    ORDER BY 
        total_net_profit DESC
    LIMIT 10
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS customer_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        c.c_customer_id
    ORDER BY 
        customer_net_profit DESC
    LIMIT 10
)
SELECT 
    ti.i_item_id,
    tc.c_customer_id,
    ti.total_quantity_sold,
    tc.customer_net_profit
FROM 
    TopItems ti
CROSS JOIN 
    TopCustomers tc
ORDER BY 
    ti.total_net_profit DESC, 
    tc.customer_net_profit DESC;
