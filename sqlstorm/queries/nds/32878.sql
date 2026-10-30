WITH  sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (
            SELECT MAX(d_date_sk) 
            FROM date_dim 
            WHERE d_year = 2001
        )
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
), ranked_sales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(sales.total_profit, 0) AS total_profit,
        COALESCE(sales.total_sales, 0) AS total_sales,
        sales.profit_rank
    FROM 
        item
    LEFT JOIN (
        SELECT 
            ws_item_sk, 
            SUM(ws_net_profit) AS total_profit,
            COUNT(ws_order_number) AS total_sales,
            ROW_NUMBER() OVER (ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
        FROM 
            web_sales
        GROUP BY 
            ws_item_sk
    ) sales ON item.i_item_sk = sales.ws_item_sk
    WHERE 
        item.i_rec_start_date <= cast('2002-10-01' as date) AND 
        (item.i_rec_end_date IS NULL OR item.i_rec_end_date > cast('2002-10-01' as date))
)
SELECT 
    r.i_item_id,
    r.i_item_desc,
    r.total_profit,
    r.total_sales,
    CASE 
        WHEN r.profit_rank < 10 THEN 'Top Performer'
        WHEN r.total_sales = 0 THEN 'No Sales'
        ELSE 'Regular Performer' 
    END AS performance_category
FROM 
    ranked_sales r
WHERE 
    r.total_profit > 1000 AND 
    r.total_sales > 5
ORDER BY 
    r.total_profit DESC
LIMIT 50;