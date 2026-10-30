
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
MaxProfit AS (
    SELECT 
        c_customer_id, 
        total_net_profit, 
        order_count
    FROM 
        CustomerSales
    WHERE 
        rn = 1
),
TopStates AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT cs.c_customer_id) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        CustomerSales cs ON c.c_customer_sk = cs.c_customer_sk
    GROUP BY 
        ca.ca_state
    ORDER BY 
        customer_count DESC
),
ItemSales AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_sales_profit
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        i.i_current_price > 20.00
    GROUP BY 
        i.i_item_id
),
TopItems AS (
    SELECT 
        i.i_item_id, 
        total_quantity_sold,
        total_sales_profit,
        ROW_NUMBER() OVER (ORDER BY total_sales_profit DESC) AS rn
    FROM 
        ItemSales i
)
SELECT 
    t.c_customer_id,
    t.total_net_profit,
    ts.ca_state,
    ti.i_item_id,
    ti.total_quantity_sold,
    ti.total_sales_profit,
    COALESCE(ti.total_sales_profit, 0) AS item_total_sales_profit
FROM 
    MaxProfit t
JOIN 
    TopStates ts ON 1=1
LEFT JOIN 
    TopItems ti ON ti.rn <= 10
WHERE 
    t.total_net_profit > (
        SELECT AVG(total_net_profit) 
        FROM MaxProfit
    )
ORDER BY 
    t.total_net_profit DESC, 
    ts.customer_count DESC, 
    ti.total_sales_profit DESC;
