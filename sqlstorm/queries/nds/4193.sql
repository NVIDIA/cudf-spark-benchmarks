
WITH RankedSales AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_net_paid DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_month_seq = (SELECT MAX(d_month_seq) FROM date_dim WHERE d_year = 2023)) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_month_seq = (SELECT MAX(d_month_seq) FROM date_dim WHERE d_year = 2023))
),
ItemReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        wr_item_sk
),
BestSellingItems AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid) AS total_net_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT DISTINCT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
ReturnImpact AS (
    SELECT 
        bsi.ws_item_sk,
        bsi.total_quantity_sold,
        bsi.total_net_sales,
        COALESCE(ir.total_returns, 0) AS total_returns,
        CAST(COALESCE(ir.total_returns, 0) AS DECIMAL) / NULLIF(bsi.total_quantity_sold, 0) * 100 AS return_percentage
    FROM 
        BestSellingItems bsi
    LEFT JOIN 
        ItemReturns ir ON bsi.ws_item_sk = ir.wr_item_sk
)
SELECT 
    rsi.ws_order_number,
    rsi.ws_item_sk,
    rsi.ws_quantity,
    rsi.ws_net_paid,
    rsi.rn,
    ri.total_quantity_sold,
    ri.total_net_sales,
    ri.total_returns,
    ri.return_percentage
FROM 
    RankedSales rsi
JOIN 
    ReturnImpact ri ON rsi.ws_item_sk = ri.ws_item_sk
WHERE 
    rsi.rn <= 5
ORDER BY 
    rsi.ws_order_number, rsi.rn;
