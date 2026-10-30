WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws.ws_sold_date_sk,
        ws.ws_item_sk
),
top_items AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        i.i_item_desc
    FROM 
        sales_summary ss
    JOIN 
        item i ON ss.ws_item_sk = i.i_item_sk
    WHERE 
        ss.rank <= 10
),
customer_returns AS (
    SELECT 
        sr_item_sk,
        COUNT(DISTINCT sr_returned_date_sk) AS return_days,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_sales
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IN (SELECT DISTINCT d_date_sk FROM date_dim WHERE d_dow = 5) 
    GROUP BY 
        sr_item_sk
)
SELECT 
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    COALESCE(cr.return_days, 0) AS return_days,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_returned_sales, 0) AS total_returned_sales,
    CASE 
        WHEN COALESCE(cr.total_returned_sales, 0) = 0 THEN 0 
        ELSE (ti.total_sales / COALESCE(cr.total_returned_sales, 1))
    END AS sales_return_ratio
FROM 
    top_items ti
LEFT JOIN 
    customer_returns cr ON ti.ws_item_sk = cr.sr_item_sk
ORDER BY 
    ti.total_sales DESC;