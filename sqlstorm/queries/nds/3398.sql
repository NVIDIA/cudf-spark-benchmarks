
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(ws_net_paid_inc_tax) AS avg_net_paid
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
top_sales AS (
    SELECT 
        ws_item_sk AS ss_item_sk,
        total_quantity,
        total_net_profit,
        avg_net_paid,
        ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS rank
    FROM 
        sales_summary
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ts.total_quantity,
    ts.total_net_profit,
    ts.avg_net_paid,
    COALESCE(r.r_reason_desc, 'No Reason') AS return_reason
FROM 
    top_sales ts
JOIN 
    item i ON ts.ss_item_sk = i.i_item_sk
LEFT JOIN 
    (SELECT 
         cr_item_sk, 
         cr_reason_sk,
         COUNT(*) AS return_count
     FROM 
         catalog_returns
     GROUP BY 
         cr_item_sk, cr_reason_sk) returns ON ts.ss_item_sk = returns.cr_item_sk
LEFT JOIN 
    reason r ON returns.cr_reason_sk = r.r_reason_sk
WHERE 
    ts.rank <= 10
ORDER BY 
    ts.total_net_profit DESC;
