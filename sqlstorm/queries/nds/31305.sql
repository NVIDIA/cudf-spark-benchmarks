
WITH  sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_sales_price) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS rn
    FROM web_sales 
    WHERE ws_sold_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY ws_sold_date_sk, ws_item_sk
), 
yearly_sales AS (
    SELECT 
        d_year AS sales_year,
        ss.ws_item_sk,
        SUM(ss.total_sales) AS yearly_quantity,
        SUM(ss.total_revenue) AS yearly_revenue
    FROM sales_summary ss
    JOIN date_dim dd ON ss.ws_sold_date_sk = dd.d_date_sk
    GROUP BY d_year, ss.ws_item_sk
), 
top_items AS (
    SELECT 
        ys.ws_item_sk,
        ys.yearly_quantity,
        ys.yearly_revenue,
        ROW_NUMBER() OVER (ORDER BY ys.yearly_revenue DESC) AS rank
    FROM yearly_sales ys
    WHERE ys.yearly_quantity > 100
)
SELECT 
    ti.ws_item_sk,
    i.i_item_desc,
    ti.yearly_quantity,
    ti.yearly_revenue,
    CASE 
        WHEN ti.yearly_revenue > 10000 THEN 'High Performer'
        ELSE 'Average Performer'
    END AS performance_category,
    COALESCE(p.p_promo_name, 'No Promotion') AS promotion_name,
    COUNT(cs.cs_order_number) AS catalog_sales_count
FROM top_items ti
LEFT JOIN item i ON ti.ws_item_sk = i.i_item_sk
LEFT JOIN promotion p ON ti.ws_item_sk = p.p_item_sk
LEFT JOIN catalog_sales cs ON ti.ws_item_sk = cs.cs_item_sk
GROUP BY 
    ti.ws_item_sk, 
    i.i_item_desc, 
    ti.yearly_quantity, 
    ti.yearly_revenue, 
    p.p_promo_name
HAVING 
    SUM(CASE WHEN cs.cs_order_number IS NULL THEN 1 ELSE 0 END) < 5
ORDER BY ti.yearly_revenue DESC;
