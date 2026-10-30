
WITH sales_data AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS item_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
), 
returns_data AS (
    SELECT 
        wr_item_sk,
        COUNT(*) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
), 
items_with_returns AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_profit,
        COALESCE(rd.total_returns, 0) AS total_returns,
        COALESCE(rd.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN COALESCE(rd.total_returns, 0) > 0 
            THEN ROUND((COALESCE(rd.total_return_amount, 0) / sd.total_profit) * 100, 2) 
            ELSE NULL 
        END AS return_percentage
    FROM 
        sales_data sd
    LEFT JOIN 
        returns_data rd ON sd.ws_item_sk = rd.wr_item_sk
    WHERE 
        sd.item_rank <= 10 
), 
final_data AS (
    SELECT 
        iw.ws_item_sk, 
        iw.total_quantity, 
        iw.total_profit, 
        iw.total_returns, 
        iw.total_return_amount, 
        iw.return_percentage,
        CASE 
            WHEN iw.return_percentage IS NULL THEN 'No Returns'
            WHEN iw.return_percentage > 20 THEN 'High Return'
            WHEN iw.return_percentage BETWEEN 10 AND 20 THEN 'Moderate Return'
            ELSE 'Low Return'
        END AS return_status
    FROM 
        items_with_returns iw
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    fd.total_quantity,
    fd.total_profit,
    fd.total_returns,
    fd.total_return_amount,
    fd.return_percentage,
    fd.return_status,
    CASE 
        WHEN fd.return_status = 'High Return' AND fd.total_profit > 1000 
            THEN 'Review Necessary'
        ELSE 'Stable'
    END AS review_status
FROM 
    final_data fd
JOIN 
    item i ON fd.ws_item_sk = i.i_item_sk
ORDER BY 
    fd.return_status, fd.total_profit DESC;
