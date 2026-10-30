
WITH customer_stats AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_id
), 
address_counts AS (
    SELECT 
        ca.ca_country,
        COUNT(DISTINCT ca.ca_address_sk) AS unique_address_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_country
), 
top_promotions AS (
    SELECT 
        p.p_promo_name,
        SUM(ws.ws_net_profit) AS total_revenue
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_name
    ORDER BY 
        total_revenue DESC
    LIMIT 5
)
SELECT 
    cs.c_customer_id,
    cs.total_net_profit,
    cs.total_orders,
    cs.avg_purchase_estimate,
    ac.unique_address_count,
    tp.p_promo_name,
    tp.total_revenue
FROM 
    customer_stats cs
JOIN 
    address_counts ac ON ac.unique_address_count > 10
JOIN 
    top_promotions tp ON tp.total_revenue > 1000
ORDER BY 
    cs.total_net_profit DESC, 
    ac.unique_address_count DESC;
