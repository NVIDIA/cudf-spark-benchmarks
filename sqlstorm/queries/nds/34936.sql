
WITH  sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
date_filtered AS (
    SELECT 
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        ss.total_quantity,
        ss.total_sales,
        ss.ws_item_sk
    FROM 
        date_dim d
    LEFT JOIN 
        sales_summary ss ON d.d_date_sk = ss.ws_sold_date_sk
    WHERE 
        d.d_year = 2001
)
SELECT 
    df.d_year,
    df.d_month_seq,
    df.d_week_seq,
    COALESCE(SUM(df.total_quantity), 0) AS total_qty,
    COALESCE(SUM(df.total_sales), 0) AS total_sales,
    COUNT(DISTINCT df.ws_item_sk) AS distinct_items_sold
FROM 
    date_filtered df
GROUP BY 
    df.d_year, df.d_month_seq, df.d_week_seq
HAVING 
    COALESCE(SUM(df.total_sales), 0) > 10000
ORDER BY 
    df.d_year, df.d_month_seq, df.d_week_seq DESC;
