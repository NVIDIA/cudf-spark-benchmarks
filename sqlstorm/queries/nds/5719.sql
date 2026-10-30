WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        p.p_start_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date = cast('2002-10-01' as date))
        AND p.p_end_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date = cast('2002-10-01' as date))
    GROUP BY 
        ws.ws_item_sk
),
ranked_sales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.order_count,
        sd.avg_net_profit,
        ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        sales_data sd
)
SELECT 
    r.ws_item_sk,
    r.total_quantity,
    r.total_sales,
    r.order_count,
    r.avg_net_profit,
    i.i_item_desc,
    i.i_brand,
    i.i_category,
    r.sales_rank
FROM 
    ranked_sales r
JOIN 
    item i ON r.ws_item_sk = i.i_item_sk
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.total_sales DESC;