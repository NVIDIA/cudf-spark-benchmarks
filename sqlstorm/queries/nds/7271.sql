
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
    GROUP BY 
        c.c_customer_sk
),

Top_Customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.order_count,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        Customer_Sales cs
),

Warehouse_Sales AS (
    SELECT 
        ws.ws_warehouse_sk,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_warehouse_sk
),

Warehouse_Profit AS (
    SELECT 
        w.w_warehouse_id,
        ws.total_profit
    FROM 
        warehouse w
    JOIN 
        Warehouse_Sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
),

Aggregate_Report AS (
    SELECT 
        tc.c_customer_sk,
        wp.w_warehouse_id,
        tc.order_count,
        tc.total_spent,
        wp.total_profit
    FROM 
        Top_Customers tc
    CROSS JOIN 
        Warehouse_Profit wp
)

SELECT 
    ag.c_customer_sk,
    ag.w_warehouse_id,
    ag.order_count,
    ag.total_spent,
    ag.total_profit
FROM 
    Aggregate_Report ag
WHERE 
    ag.total_spent > 1000
ORDER BY 
    ag.total_profit DESC, ag.total_spent DESC
LIMIT 100;
