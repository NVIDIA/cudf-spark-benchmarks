
WITH  base_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid) AS total_sales,
        DENSE_RANK() OVER (ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
highest_sales AS (
    SELECT 
        bs.ws_item_sk,
        bs.total_sales,
        i.i_item_desc,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY bs.total_sales DESC) as category_rank
    FROM 
        base_sales bs
    JOIN 
        item i ON bs.ws_item_sk = i.i_item_sk
    WHERE 
        bs.sales_rank <= 50
),
sales_summary AS (
    SELECT 
        h.ws_item_sk,
        h.total_sales,
        h.i_item_desc,
        COALESCE(SUM(sr_return_amt), 0) AS total_returns
    FROM 
        highest_sales h
    LEFT JOIN 
        store_returns sr ON h.ws_item_sk = sr.sr_item_sk
    GROUP BY 
        h.ws_item_sk, h.total_sales, h.i_item_desc
)
SELECT 
    ss.ws_item_sk,
    ss.i_item_desc,
    ss.total_sales,
    ss.total_returns,
    (ss.total_sales - ss.total_returns) AS net_sales,
    CASE 
        WHEN ss.total_returns > 0 THEN (ss.total_returns * 100.0 / NULLIF(ss.total_sales, 0))
        ELSE 0
    END AS return_percentage
FROM 
    sales_summary ss
WHERE 
    ss.total_sales > 1000
ORDER BY 
    net_sales DESC
LIMIT 10;
