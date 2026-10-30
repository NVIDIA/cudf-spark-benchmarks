
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk 
                                FROM date_dim d 
                                WHERE d.d_year = 2023)
),
TotalSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_ext_sales_price) AS TotalSalesAmount
    FROM 
        RankedSales rs
    WHERE 
        rs.SalesRank <= 10
    GROUP BY 
        rs.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(cr.cr_return_amount), 0) AS TotalReturns
    FROM 
        customer c
    LEFT JOIN 
        (SELECT cr_returning_customer_sk, cr_return_amount 
         FROM catalog_returns 
         WHERE cr_returned_date_sk IN (SELECT d.d_date_sk
                                        FROM date_dim d
                                        WHERE d.d_year = 2023)) AS cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cs.TotalSalesAmount,
    cr.TotalReturns,
    CASE 
        WHEN cr.TotalReturns > 0 THEN 'Returns Made'
        ELSE 'No Returns'
    END AS ReturnStatus
FROM 
    customer c
LEFT JOIN 
    TotalSales cs ON c.c_customer_sk = cs.ws_item_sk
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.c_customer_sk
WHERE 
    cs.TotalSalesAmount > 1000 OR cr.TotalReturns > 0
ORDER BY 
    cs.TotalSalesAmount DESC NULLS LAST;
