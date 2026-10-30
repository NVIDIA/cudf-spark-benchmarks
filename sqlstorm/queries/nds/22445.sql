
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0 AND
        EXISTS (
            SELECT 1 
            FROM promotion p 
            WHERE p.p_item_sk = ws.ws_item_sk AND 
                  p.p_start_date_sk <= ws.ws_sold_date_sk AND 
                  p.p_end_date_sk >= ws.ws_sold_date_sk
        )
    GROUP BY 
        ws.ws_item_sk
), 
seasonal_returns AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(CASE WHEN wr_returned_date_sk BETWEEN 20220101 AND 20220131 THEN wr_return_amt ELSE 0 END) AS january_returns
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    i.i_item_id,
    r.total_quantity,
    sr.total_returns,
    sr.total_return_amt,
    sr.january_returns,
    CASE 
        WHEN r.total_quantity > 100 THEN 'High Demand' 
        ELSE 'Low Demand' 
    END AS demand_category,
    CONCAT('Item ', i.i_item_desc, ' has ', 
           COALESCE(CAST(sr.january_returns AS STRING), 'no'), 
           ' returns in January') AS return_summary
FROM 
    ranked_sales r
LEFT JOIN 
    seasonal_returns sr ON r.ws_item_sk = sr.wr_item_sk
JOIN 
    item i ON r.ws_item_sk = i.i_item_sk
WHERE 
    (sr.total_returns IS NULL OR sr.total_return_amt > 500) AND 
    (i.i_current_price BETWEEN 10 AND 50 OR i.i_size IS NULL)
ORDER BY 
    r.rank ASC, sr.january_returns DESC;
