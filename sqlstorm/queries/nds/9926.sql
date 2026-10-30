
WITH CustomerOrders AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(COALESCE(ws.ws_net_paid_inc_tax, 0) + COALESCE(cs.cs_net_paid_inc_tax, 0) + COALESCE(ss.ss_net_paid_inc_tax, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1950 AND 2000
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),

PromotionsUsed AS (
    SELECT 
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450599 /* Sample date range for a month */
    GROUP BY 
        p.p_promo_name
)

SELECT 
    co.c_customer_id,
    co.cd_gender,
    co.cd_marital_status,
    co.total_spent,
    co.web_orders,
    co.catalog_orders,
    co.store_orders,
    pu.p_promo_name AS promo_name,
    pu.total_orders,
    pu.total_profit
FROM 
    CustomerOrders co
LEFT JOIN 
    PromotionsUsed pu ON co.total_spent > 1000 /* Customers who spent more than $1000 */
ORDER BY 
    co.total_spent DESC, pu.total_profit DESC
LIMIT 50;
