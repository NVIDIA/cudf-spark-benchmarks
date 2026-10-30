
WITH customer_promotions AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        p.p_promo_id, 
        p.p_promo_name, 
        p.p_cost, 
        SUM(ws.ws_quantity) AS total_sales_volume, 
        SUM(ws.ws_ext_sales_price) AS total_sales_value
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN promotion p ON p.p_item_sk = ws.ws_item_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        p.p_promo_id, 
        p.p_promo_name, 
        p.p_cost
), ranked_promotions AS (
    SELECT 
        c.*, 
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY c.total_sales_value DESC) AS rank
    FROM customer_promotions c
)
SELECT 
    rp.c_customer_id,
    rp.c_first_name,
    rp.c_last_name,
    rp.p_promo_id,
    rp.p_promo_name,
    rp.p_cost,
    rp.total_sales_volume,
    rp.total_sales_value
FROM ranked_promotions rp
WHERE rp.rank = 1
ORDER BY rp.total_sales_value DESC
LIMIT 100;
