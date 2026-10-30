
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_web_page_sk) AS distinct_pages_viewed
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year >= 1980
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_profit,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS profit_rank
    FROM 
        CustomerSales cs 
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_profit > 5000
),
ShippingModes AS (
    SELECT 
        sm.sm_type,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_type
)
SELECT 
    tc.c_customer_id,
    tc.total_profit AS customer_profit,
    tc.order_count AS customer_orders,
    sm.sm_type AS shipping_mode,
    sm.total_orders AS mode_total_orders,
    sm.total_profit AS mode_total_profit
FROM 
    TopCustomers tc
JOIN 
    ShippingModes sm ON tc.order_count > 10
WHERE 
    sm.total_profit > (SELECT AVG(total_profit) FROM ShippingModes) 
ORDER BY 
    tc.total_profit DESC, sm.total_profit DESC
LIMIT 100;
