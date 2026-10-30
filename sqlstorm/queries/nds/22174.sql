
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_sales_price) AS total_sales_amount,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2022
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
MaxSales AS (
    SELECT 
        rs.ws_item_sk,
        MAX(rs.total_sales_amount) AS max_sales_amount,
        COUNT(rs.ws_sold_date_sk) AS sales_days
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank = 1
    GROUP BY 
        rs.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned_quantity,
        SUM(wr.wr_return_amt) AS total_returned_amount
    FROM 
        web_returns wr
    JOIN 
        web_sales ws ON wr.wr_item_sk = ws.ws_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20190101 AND 20201231
    GROUP BY 
        wr.wr_item_sk
),
FinalReport AS (
    SELECT 
        COALESCE(m.ws_item_sk, c.wr_item_sk) AS item_sk,
        m.max_sales_amount,
        COALESCE(c.total_returned_amount, 0) AS total_returned_amount,
        CASE 
            WHEN m.max_sales_amount IS NULL THEN 'NO SALES'
            WHEN COALESCE(c.total_returned_amount, 0) > m.max_sales_amount THEN 'RETURN EXCEEDS SALES'
            ELSE 'NORMAL'
        END AS sales_return_status
    FROM 
        MaxSales m
    FULL OUTER JOIN 
        CustomerReturns c ON m.ws_item_sk = c.wr_item_sk
)
SELECT 
    f.item_sk,
    f.max_sales_amount,
    f.total_returned_amount,
    f.sales_return_status,
    (SELECT AVG(ss.ss_net_profit) 
     FROM store_sales ss 
     WHERE ss.ss_item_sk = f.item_sk 
       AND ss.ss_sold_date_sk BETWEEN 20200301 AND 20210301) AS avg_store_net_profit
FROM 
    FinalReport f
WHERE 
    f.sales_return_status != 'NO SALES'
ORDER BY 
    f.max_sales_amount DESC;
