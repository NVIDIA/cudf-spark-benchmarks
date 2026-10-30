
WITH  SalesCTE AS (
    SELECT 
        cs_item_sk, 
        SUM(cs_net_profit) AS Total_Profit, 
        COUNT(cs_order_number) AS Total_Orders,
        ROW_NUMBER() OVER (ORDER BY SUM(cs_net_profit) DESC) AS Rank
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        cs_item_sk
),
TopSales AS (
    SELECT 
        S.cs_item_sk, 
        I.i_item_desc, 
        S.Total_Profit,
        S.Total_Orders 
    FROM 
        SalesCTE S
    JOIN 
        item I ON S.cs_item_sk = I.i_item_sk
    WHERE 
        S.Rank <= 10
),
CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(CASE 
                WHEN cr_return_quantity IS NOT NULL THEN cr_return_quantity 
                ELSE 0 
            END) AS Total_Returned,
        COUNT(DISTINCT cr_order_number) AS Total_Returns
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
FinalReport AS (
    SELECT 
        C.c_customer_id,
        CA.ca_city,
        T.Total_Profit,
        R.Total_Returned,
        R.Total_Returns
    FROM 
        TopSales T
    LEFT JOIN 
        customer C ON C.c_customer_sk = (SELECT MIN(cr_returning_customer_sk) FROM CustomerReturns)
    JOIN 
        customer_address CA ON C.c_current_addr_sk = CA.ca_address_sk
    LEFT JOIN 
        CustomerReturns R ON R.cr_returning_customer_sk = C.c_customer_sk
)
SELECT 
    F.c_customer_id,
    F.ca_city,
    F.Total_Profit,
    COALESCE(F.Total_Returned, 0) AS Total_Returned,
    COALESCE(F.Total_Returns, 0) AS Total_Returns
FROM 
    FinalReport F
ORDER BY 
    F.Total_Profit DESC;
