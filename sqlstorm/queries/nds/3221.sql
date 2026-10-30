
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank,
        w_warehouse_id
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws_sold_date_sk BETWEEN 2451545 AND 2451545 + 30  
),
CustomerTotals AS (
    SELECT
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
ProfitAnalysis AS (
    SELECT
        ct.c_customer_id,
        ct.total_orders,
        ct.total_profit,
        CASE
            WHEN ct.total_profit IS NULL THEN 'No Profit'
            WHEN ct.total_profit > 0 THEN 'Profit'
            ELSE 'Loss'
        END AS profit_status
    FROM 
        CustomerTotals ct
)
SELECT 
    ra.ws_item_sk,
    ra.ws_sales_price,
    ca.c_customer_id,
    ca.total_orders,
    ca.total_profit,
    ca.profit_status,
    ra.w_warehouse_id
FROM 
    RankedSales ra
JOIN 
    ProfitAnalysis ca ON ca.total_orders > 5  
WHERE 
    ra.price_rank = 1
ORDER BY 
    ra.ws_sales_price DESC,
    ca.total_profit DESC
LIMIT 100;
