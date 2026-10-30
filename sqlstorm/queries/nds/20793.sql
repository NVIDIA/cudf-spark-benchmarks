
WITH sales_data AS (
    SELECT 
        ws.ws_web_site_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sale_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY 
        ws.ws_web_site_sk
), top_sales AS (
    SELECT * 
    FROM sales_data 
    WHERE sale_rank <= 5
), item_returns AS (
    SELECT 
        ir.cr_item_sk,
        SUM(ir.cr_return_quantity) AS total_returned,
        COUNT(ir.cr_order_number) AS return_count
    FROM 
        catalog_returns ir
    GROUP BY 
        ir.cr_item_sk
), item_sales AS (
    SELECT 
        i.i_item_sk,
        SUM(COALESCE(ss.ss_quantity, 0) + COALESCE(cs.cs_quantity, 0) + COALESCE(ws.ws_quantity, 0)) AS total_sold,
        SUM(COALESCE(ss.ss_net_paid_inc_tax, 0) + COALESCE(cs.cs_net_paid_inc_tax, 0) + COALESCE(ws.ws_net_paid_inc_tax, 0)) AS total_revenue
    FROM 
        item i
    LEFT JOIN 
        store_sales ss ON i.i_item_sk = ss.ss_item_sk
    LEFT JOIN 
        catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    COALESCE(s.total_quantity, 0) AS web_total_quantity,
    COALESCE(s.total_net_paid, 0) AS web_total_net_paid,
    COALESCE(r.total_returned, 0) AS total_returned,
    COALESCE(r.return_count, 0) AS return_records,
    COALESCE(s.total_quantity, 0) - COALESCE(r.total_returned, 0) AS net_sales,
    i.i_current_price,
    (COALESCE(s.total_net_paid, 0) - COALESCE(r.total_returned * i.i_current_price, 0)) AS net_revenue_after_returns
FROM 
    item i
LEFT JOIN 
    top_sales s ON s.ws_web_site_sk = i.i_item_sk
LEFT JOIN 
    item_returns r ON r.cr_item_sk = i.i_item_sk
WHERE 
    (i.i_current_price IS NOT NULL AND i.i_current_price > 0)
    AND (COALESCE(s.total_quantity, 0) > 10 OR COALESCE(r.total_returned, 0) > 5)
ORDER BY 
    net_sales DESC
LIMIT 50;
