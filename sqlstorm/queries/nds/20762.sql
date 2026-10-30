
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS Rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
HighValueItems AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        SUM(rs.ws_sales_price) AS Total_Sales,
        COUNT(rs.ws_order_number) AS Order_Count
    FROM 
        item i
    JOIN 
        RankedSales rs ON i.i_item_sk = rs.ws_item_sk
    WHERE 
        rs.Rank <= 5
    GROUP BY 
        i.i_item_sk, i.i_item_desc
),
CustomerReturns AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_quantity) AS Total_Returns,
        COUNT(DISTINCT sr.sr_ticket_number) AS Return_Count
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    CASE 
        WHEN hvi.Total_Sales IS NULL THEN 'No Sales'
        ELSE 'Has Sales'
    END AS Sales_Status,
    COALESCE(hvi.Total_Sales, 0) AS High_Value_Sales,
    COALESCE(cr.Total_Returns, 0) AS Total_Returns,
    COALESCE(cr.Return_Count, 0) AS Return_Transactions
FROM 
    customer c
LEFT JOIN 
    HighValueItems hvi ON c.c_customer_sk = hvi.i_item_sk
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
WHERE 
    c.c_birth_year IS NOT NULL 
    AND c.c_birth_month IS NOT NULL
    AND (c.c_current_cdemo_sk IS NOT NULL OR c.c_current_hdemo_sk IS NOT NULL)
    AND c.c_preferred_cust_flag = 'Y'
    AND (c.c_birth_month + c.c_birth_day) % 2 = 0
ORDER BY 
    Total_Returns DESC, High_Value_Sales DESC
LIMIT 50;
