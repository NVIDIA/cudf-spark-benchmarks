
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        ws.ws_item_sk
),
promo_effect AS (
    SELECT 
        cs.cs_item_sk,
        COUNT(DISTINCT cs.cs_order_number) AS promo_orders,
        SUM(CASE WHEN cs.cs_ext_discount_amt > 0 THEN cs.cs_ext_sales_price ELSE 0 END) AS total_discounted_sales
    FROM 
        catalog_sales cs
    JOIN 
        promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        cs.cs_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(ss.total_quantity, 0) AS total_quantity,
    COALESCE(ss.total_net_paid, 0) AS total_net_paid,
    COALESCE(pe.promo_orders, 0) AS promo_orders,
    COALESCE(pe.total_discounted_sales, 0) AS total_discounted_sales,
    CASE 
        WHEN COALESCE(pe.total_discounted_sales, 0) > 0 THEN 
            (COALESCE(ss.total_net_paid, 0) / NULLIF(pe.total_discounted_sales, 0)) * 100 
        ELSE 0 
    END AS promo_sales_ratio
FROM 
    item i
LEFT JOIN 
    sales_summary ss ON i.i_item_sk = ss.ws_item_sk
LEFT JOIN 
    promo_effect pe ON i.i_item_sk = pe.cs_item_sk
WHERE 
    i.i_current_price > (SELECT AVG(i_current_price) FROM item) 
ORDER BY 
    total_net_paid DESC
LIMIT 10;
