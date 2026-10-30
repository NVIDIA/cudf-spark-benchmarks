
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        COUNT(ws_order_number) AS total_sales,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 10 LIMIT 1)
        AND (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 10 ORDER BY d_date_sk DESC LIMIT 1)
    GROUP BY 
        ws_item_sk
),
ItemDetails AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price
    FROM 
        item
    WHERE 
        i_rec_start_date <= (SELECT d_date FROM date_dim WHERE d_year = 2023 AND d_month_seq = 10 AND d_dow = 6 LIMIT 1)
        AND (i_rec_end_date IS NULL OR i_rec_end_date >= (SELECT d_date FROM date_dim WHERE d_year = 2023 AND d_month_seq = 10 AND d_dow = 6 LIMIT 1))
),
HighProfitItems AS (
    SELECT 
        r.ws_item_sk,
        r.total_sales,
        r.total_net_profit,
        i.i_item_desc,
        i.i_current_price
    FROM 
        RankedSales r
    INNER JOIN 
        ItemDetails i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.rank <= 5
)
SELECT 
    h.ws_item_sk,
    h.i_item_desc,
    h.total_sales,
    h.total_net_profit,
    CASE 
        WHEN h.total_net_profit IS NOT NULL AND h.total_sales > 0 THEN (h.total_net_profit / NULLIF(h.total_sales, 0)) 
        ELSE NULL 
    END AS avg_profit_per_sale
FROM 
    HighProfitItems h
ORDER BY 
    h.total_net_profit DESC;
