
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990 
    GROUP BY 
        c.c_customer_id
),
PromotedSales AS (
    SELECT 
        cs.c_customer_id,
        cs.total_web_sales,
        cs.order_count,
        cs.avg_profit,
        p.p_discount_active
    FROM 
        CustomerSales cs
    LEFT JOIN 
        promotion p ON cs.order_count >= p.p_response_target
    WHERE 
        cs.total_web_sales > 1000
)
SELECT 
    ps.c_customer_id,
    ps.total_web_sales,
    ps.order_count,
    ps.avg_profit,
    (CASE WHEN ps.p_discount_active = 'Y' THEN 'Active Promotion' ELSE 'No Promotion' END) AS promotion_status
FROM 
    PromotedSales ps
WHERE 
    ps.avg_profit > 50
ORDER BY 
    ps.total_web_sales DESC
LIMIT 20;
