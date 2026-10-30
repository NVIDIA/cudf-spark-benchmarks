
WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_sales_price) DESC) AS sales_rank
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        cs_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(RS.total_sales, 0) AS total_sales,
    COALESCE(CR.total_returns, 0) AS total_returns,
    COALESCE(CR.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN COALESCE(RS.total_sales, 0) > 0 THEN ROUND(COALESCE(CR.total_return_amount, 0) / COALESCE(RS.total_sales, 0) * 100, 2)
        ELSE NULL 
    END AS return_rate_percentage
FROM 
    item i
LEFT JOIN 
    RankedSales RS ON i.i_item_sk = RS.cs_item_sk
LEFT JOIN 
    CustomerReturns CR ON i.i_item_sk = CR.sr_item_sk
WHERE 
    (RS.sales_rank = 1 OR RS.sales_rank IS NULL)
    AND i.i_current_price > (
        SELECT AVG(i_current_price) FROM item
    )
ORDER BY 
    return_rate_percentage DESC
LIMIT 10;
