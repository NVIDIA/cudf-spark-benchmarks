
WITH  sales_data AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(ws.ws_order_number) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    INNER JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws.ws_item_sk
),
returns_data AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(wr.wr_order_number) AS total_returns,
        SUM(wr.wr_return_amt) AS total_returned
    FROM 
        web_returns wr
    WHERE 
        EXISTS (
            SELECT 1 
            FROM sales_data sd 
            WHERE sd.ws_item_sk = wr.wr_item_sk
        )
    GROUP BY 
        wr.wr_item_sk
),
final_report AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sales,
        sd.total_profit,
        COALESCE(rd.total_returns, 0) AS total_returns,
        COALESCE(rd.total_returned, 0) AS total_returned_adjusted,
        CASE 
            WHEN sd.total_profit > 0 THEN (sd.total_profit - COALESCE(rd.total_returned, 0)) / NULLIF(sd.total_sales, 0)
            ELSE NULL
        END AS profit_per_sale
    FROM 
        sales_data sd
    LEFT JOIN 
        returns_data rd ON sd.ws_item_sk = rd.wr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    fr.total_sales,
    fr.total_profit,
    fr.total_returns,
    fr.total_returned_adjusted,
    fr.profit_per_sale
FROM 
    final_report fr
JOIN 
    item i ON fr.ws_item_sk = i.i_item_sk
WHERE 
    fr.profit_per_sale IS NOT NULL
    AND fr.total_sales > 5
ORDER BY 
    fr.profit_per_sale DESC
LIMIT 10;
