
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesRANK AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        total_quantity,
        total_net_profit,
        total_orders,
        ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS rank
    FROM 
        CustomerSales c
),
PromotionSales AS (
    SELECT 
        p.p_promo_id,
        SUM(ws.ws_net_profit) AS promo_net_profit
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_quantity,
    cs.total_net_profit,
    ps.promo_net_profit,
    CASE 
        WHEN cs.total_net_profit IS NULL THEN 'No Sales'
        ELSE 'Sales Made'
    END AS sales_status
FROM 
    SalesRANK cs
LEFT JOIN 
    PromotionSales ps ON cs.total_orders > 5
WHERE 
    cs.rank <= 10
ORDER BY 
    cs.total_net_profit DESC;
