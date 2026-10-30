
WITH SalesPerformance AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (
            SELECT 
                d_date_sk 
            FROM 
                date_dim 
            WHERE 
                d_year = 2023 AND d_moy IN (1, 2, 3)
        )
    GROUP BY 
        ws_item_sk
), ReturnData AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt) AS total_returned_amt
    FROM 
        web_returns 
    WHERE 
        wr_returned_date_sk IN (
            SELECT 
                d_date_sk 
            FROM 
                date_dim 
            WHERE 
                d_year = 2023 AND d_moy IN (1, 2, 3)
        )
    GROUP BY 
        wr_item_sk
)
SELECT 
    s.ws_item_sk,
    s.total_quantity,
    s.total_sales,
    s.total_profit,
    COALESCE(r.total_returned, 0) AS total_returned,
    COALESCE(r.total_returned_amt, 0) AS total_returned_amt,
    (s.total_profit - COALESCE(r.total_returned_amt, 0)) AS net_profit_after_returns
FROM 
    SalesPerformance s
LEFT JOIN 
    ReturnData r ON s.ws_item_sk = r.wr_item_sk
WHERE 
    s.rank_profit <= 10
ORDER BY 
    net_profit_after_returns DESC;
