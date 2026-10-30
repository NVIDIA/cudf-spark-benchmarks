WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS Total_Sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank_sales
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2459959 AND 2463585 
    GROUP BY ws_item_sk
),
TopSales AS (
    SELECT ws_item_sk, Total_Sales
    FROM RankedSales
    WHERE rank_sales <= 10
),
ReturnDetails AS (
    SELECT 
        wr_item_sk,
        COUNT(*) AS Return_Count,
        SUM(wr_return_amt_inc_tax) AS Total_Return_Amount,
        SUM(wr_net_loss) AS Total_Net_Loss
    FROM web_returns
    GROUP BY wr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(ts.Total_Sales, 0) AS Total_Sales,
    COALESCE(rd.Return_Count, 0) AS Return_Count,
    COALESCE(rd.Total_Return_Amount, 0) AS Total_Return_Amount,
    COALESCE(rd.Total_Net_Loss, 0) AS Total_Net_Loss,
    CASE 
        WHEN COALESCE(ts.Total_Sales, 0) = 0 THEN 'No Sales'
        WHEN COALESCE(rd.Return_Count, 0) > 0 THEN 'Returned'
        ELSE 'Active'
    END AS Sale_Status
FROM item i
LEFT JOIN TopSales ts ON i.i_item_sk = ts.ws_item_sk
LEFT JOIN ReturnDetails rd ON i.i_item_sk = rd.wr_item_sk
WHERE 
    i.i_current_price > (
        SELECT AVG(i_current_price) 
        FROM item 
        WHERE i_rec_start_date <= cast('2002-10-01' as date) AND i_rec_end_date > cast('2002-10-01' as date)
    )
    AND (i.i_item_desc LIKE '%special%' OR i.i_item_desc IS NULL)
ORDER BY 
    Total_Sales DESC,
    Return_Count ASC;