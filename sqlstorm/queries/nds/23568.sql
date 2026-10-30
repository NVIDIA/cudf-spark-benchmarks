
WITH SalesData AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_net_profit) AS Total_Profit,
        COUNT(DISTINCT cs.cs_order_number) AS Total_Orders,
        MAX(cs.cs_sold_date_sk) AS Last_Sold_Date
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_quantity > 0
    GROUP BY 
        cs.cs_item_sk
),
TopItems AS (
    SELECT 
        sd.cs_item_sk,
        sd.Total_Profit,
        sd.Total_Orders,
        ROW_NUMBER() OVER (ORDER BY sd.Total_Profit DESC) AS Profit_Rank
    FROM 
        SalesData sd
    WHERE 
        sd.Total_Orders > (SELECT AVG(Total_Orders) FROM SalesData)
),
ReturnStats AS (
    SELECT 
        wr.wr_item_sk, 
        COUNT(wr.wr_order_number) AS Total_Returns, 
        SUM(wr.wr_return_amt) AS Total_Returned_Amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(ti.Total_Profit, 0) AS Profit,
    COALESCE(ti.Total_Orders, 0) AS Orders,
    COALESCE(rs.Total_Returns, 0) AS Returns,
    CASE 
        WHEN COALESCE(rs.Total_Returns, 0) = 0 THEN 'No Returns'
        ELSE 'Returned'
    END AS Return_Status,
    CASE 
        WHEN ti.Profit_Rank <= 10 THEN 'Top Selling'
        WHEN ti.Profit_Rank IS NULL THEN 'No Sales'
        ELSE 'Other'
    END AS Sales_Category
FROM 
    item i
LEFT JOIN 
    TopItems ti ON i.i_item_sk = ti.cs_item_sk
LEFT JOIN 
    ReturnStats rs ON i.i_item_sk = rs.wr_item_sk
WHERE 
    (ti.Total_Profit IS NOT NULL AND ti.Total_Orders IS NOT NULL)
    OR 
    (rs.Total_Returns IS NULL AND ti.Total_Profit IS NULL)
ORDER BY 
    Profit DESC, Orders DESC;
