
WITH sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        pd.p_promo_name
    FROM 
        web_sales ws
    LEFT JOIN 
        promotion pd ON ws.ws_promo_sk = pd.p_promo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2458743 AND 2458770
)
SELECT 
    s.ws_order_number,
    SUM(s.ws_quantity) AS total_quantity,
    SUM(s.ws_ext_sales_price) AS total_sales,
    SUM(s.ws_net_paid) AS total_net_paid,
    COUNT(DISTINCT s.ws_item_sk) AS distinct_items,
    s.p_promo_name
FROM 
    sales_data s
GROUP BY 
    s.ws_order_number, s.p_promo_name
ORDER BY 
    total_sales DESC
LIMIT 100;
