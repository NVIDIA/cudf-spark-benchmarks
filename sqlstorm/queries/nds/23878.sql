
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
promotion_summary AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        COALESCE(SUM(ws.ws_net_profit), 0) AS promo_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
),
store_data AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        COUNT(ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_net_profit) AS total_store_profit
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        COALESCE(ss.ss_net_profit, 0) > 0
    GROUP BY 
        s.s_store_sk, s.s_store_name
),
category_profit AS (
    SELECT 
        i.i_category_id,
        SUM(ws.ws_net_profit) AS category_profit
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
        AND i.i_size IS NOT NULL 
    GROUP BY 
        i.i_category_id
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    AVG(rd.total_net_profit) AS avg_profit_per_customer,
    MAX(ps.promo_net_profit) AS max_promo_profit,
    MIN(sd.total_store_profit) AS min_store_profit,
    STRING_AGG(DISTINCT CAST(cp.category_profit AS STRING), ', ') AS category_profits
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    ranked_sales rd ON c.c_customer_sk = rd.ws_item_sk
LEFT JOIN 
    promotion_summary ps ON ps.promo_net_profit > 0
LEFT JOIN 
    store_data sd ON sd.total_sales > 5
LEFT JOIN 
    category_profit cp ON cp.category_profit IS NOT NULL
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT rd.ws_item_sk) > 10
ORDER BY 
    unique_customers DESC
LIMIT 100;
