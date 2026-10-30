WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_ext_sales_price) AS Total_Sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS Sales_Rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F'
        AND i.i_current_price > 10.00
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
CustomerReturns AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(wr.wr_order_number) AS Return_Count,
        SUM(wr.wr_return_amt) AS Total_Return_Amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    ir.i_item_desc,
    COALESCE(rs.Total_Sales, 0) AS Total_Sales,
    COALESCE(cr.Return_Count, 0) AS Return_Count,
    COALESCE(cr.Total_Return_Amount, 0) AS Total_Return_Amount,
    COALESCE(rs.Total_Sales, 0) - COALESCE(cr.Total_Return_Amount, 0) AS Net_Earnings
FROM 
    item ir
LEFT JOIN 
    RankedSales rs ON ir.i_item_sk = rs.ws_item_sk AND rs.Sales_Rank = 1
LEFT JOIN 
    CustomerReturns cr ON ir.i_item_sk = cr.wr_item_sk
WHERE 
    ir.i_rec_start_date <= cast('2002-10-01' as date) 
    AND (ir.i_rec_end_date IS NULL OR ir.i_rec_end_date > cast('2002-10-01' as date))
ORDER BY 
    Net_Earnings DESC
LIMIT 10;