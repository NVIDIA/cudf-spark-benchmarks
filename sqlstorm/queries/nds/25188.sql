
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, ca.ca_city
),
PromotedProducts AS (
    SELECT 
        p.p_promo_id,
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS promotion_usage,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id, p.p_promo_name
),
FinalReport AS (
    SELECT 
        cs.full_name,
        cs.ca_city,
        cs.total_orders,
        cs.total_spent,
        pp.promotion_usage,
        pp.total_sales
    FROM 
        CustomerStats cs
    LEFT JOIN 
        PromotedProducts pp ON cs.total_orders > 0
    ORDER BY 
        cs.total_spent DESC
)
SELECT 
    full_name,
    ca_city,
    total_orders,
    total_spent,
    COALESCE(promotion_usage, 0) AS promotion_usage,
    COALESCE(total_sales, 0.00) AS total_sales
FROM 
    FinalReport
WHERE 
    total_spent > 0
LIMIT 100;
