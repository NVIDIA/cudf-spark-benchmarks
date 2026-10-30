
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS SalesRank
    FROM 
        web_sales ws 
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim) 
),
TotalReturnValue AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        store_returns 
    GROUP BY 
        sr_item_sk
),
TopSellingItems AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_quantity * rs.ws_sales_price) AS total_sales_value
    FROM 
        RankedSales rs
    GROUP BY 
        rs.ws_item_sk
    HAVING 
        COUNT(*) > 5
),
FinalReport AS (
    SELECT 
        tsi.ws_item_sk,
        tsi.total_sales_value,
        COALESCE(trv.total_returned_amount, 0) AS total_returns,
        (tsi.total_sales_value - COALESCE(trv.total_returned_amount, 0)) AS net_value
    FROM 
        TopSellingItems tsi
    LEFT JOIN 
        TotalReturnValue trv ON tsi.ws_item_sk = trv.sr_item_sk
)
SELECT 
    fe.ws_item_sk,
    fe.total_sales_value,
    fe.total_returns,
    fe.net_value,
    CASE 
        WHEN fe.net_value > 1000 THEN 'High Value'
        WHEN fe.net_value BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_category
FROM 
    FinalReport fe
ORDER BY 
    fe.net_value DESC;
