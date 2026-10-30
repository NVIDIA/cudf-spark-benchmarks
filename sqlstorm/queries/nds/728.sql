
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_ext_sales_price,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rank_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS total_quantity,
        SUM(rs.ws_ext_sales_price) AS total_sales,
        SUM(rs.ws_net_profit) AS total_net_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rank_sales <= 5
    GROUP BY 
        rs.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(ts.total_quantity, 0) AS total_quantity,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(ts.total_net_profit, 0) AS total_net_profit,
    (CASE 
        WHEN ts.total_net_profit IS NOT NULL AND ts.total_net_profit > 0 THEN 'Profitable'
        WHEN ts.total_net_profit IS NULL AND (SELECT SUM(ws_net_profit) FROM web_sales WHERE ws_item_sk = i.i_item_sk) < 0 THEN 'Loss'
        ELSE 'No Sales'
     END) AS sales_status
FROM 
    item i
LEFT JOIN 
    TopSales ts ON i.i_item_sk = ts.ws_item_sk
WHERE 
    (SELECT COUNT(*) FROM store_sales WHERE ss_item_sk = i.i_item_sk AND ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)) > 0
ORDER BY 
    total_net_profit DESC, 
    total_sales DESC;
