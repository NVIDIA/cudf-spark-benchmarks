
WITH SalesAnalysis AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        da.ca_city,
        da.ca_state,
        sa.total_quantity,
        sa.total_profit
    FROM 
        customer c
    JOIN 
        customer_address da ON c.c_current_addr_sk = da.ca_address_sk
    JOIN 
        SalesAnalysis sa ON c.c_customer_sk = sa.ws_bill_customer_sk
    WHERE 
        sa.total_profit > (SELECT AVG(total_profit) FROM SalesAnalysis)
    AND 
        da.ca_country = 'USA'
),
RecentCustomerPurchases AS (
    SELECT 
        c.c_customer_id,
        COUNT(ws.ws_order_number) AS recent_orders
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    GROUP BY 
        c.c_customer_id
)
SELECT 
    hvc.c_customer_id,
    hvc.ca_city,
    hvc.ca_state,
    hvc.total_quantity,
    hvc.total_profit,
    rcp.recent_orders,
    CASE 
        WHEN rcp.recent_orders IS NULL THEN 'No purchases today'
        WHEN rcp.recent_orders > 5 THEN 'Frequent buyer'
        ELSE 'Occasional buyer'
    END AS customer_category
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    RecentCustomerPurchases rcp ON hvc.c_customer_id = rcp.c_customer_id
ORDER BY 
    hvc.total_profit DESC, 
    rcp.recent_orders DESC
LIMIT 100;
