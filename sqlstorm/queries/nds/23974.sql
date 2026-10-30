WITH sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
        AND ws.ws_net_profit IS NOT NULL
    GROUP BY 
        ws.ws_item_sk
),
catalog AS (
    SELECT 
        cs.cs_item_sk,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        MIN(cs.cs_sales_price) AS min_sales_price
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sold_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2000)
    GROUP BY 
        cs.cs_item_sk
),
returns AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
    HAVING 
        COUNT(*) > 5
)
SELECT 
    COALESCE(i.i_item_id, 'UNKNOWN') AS item_id,
    COALESCE(c.total_sales, 0) AS total_catalog_sales,
    COALESCE(s.total_quantity, 0) AS total_web_sales,
    COALESCE(r.total_returns, 0) AS total_store_returns,
    COALESCE(r.total_return_value, 0) AS total_return_value,
    CASE 
        WHEN s.profit_rank = 1 THEN 'Top Performer'
        WHEN s.profit_rank IS NULL AND c.order_count > 10 THEN 'Potential'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    item i
LEFT JOIN 
    sales s ON i.i_item_sk = s.ws_item_sk
LEFT JOIN 
    catalog c ON i.i_item_sk = c.cs_item_sk
LEFT JOIN 
    returns r ON i.i_item_sk = r.sr_item_sk
WHERE 
    i.i_current_price IS NOT NULL 
    AND i.i_rec_start_date <= cast('2002-10-01' as date) 
    AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > cast('2002-10-01' as date))
ORDER BY 
    total_net_profit DESC NULLS LAST, 
    total_sales DESC, 
    total_web_sales DESC;