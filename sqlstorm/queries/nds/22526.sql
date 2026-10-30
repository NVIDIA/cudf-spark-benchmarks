
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL AND 
        (ws.ws_ext_sales_price IS NOT NULL OR ws.ws_ext_discount_amt IS NULL)
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        (SELECT AVG(cust_count) 
         FROM (SELECT COUNT(DISTINCT ws.ws_order_number) AS cust_count
               FROM web_sales ws 
               WHERE ws.ws_bill_customer_sk = c.c_customer_sk 
               GROUP BY ws.ws_bill_customer_sk) AS cust_counts) AS AvgPurchaseCount
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
    AND 
        cd.cd_credit_rating IS NOT NULL
),
SalesSummary AS (
    SELECT 
        ci.c_customer_sk, 
        ci.c_first_name,
        ci.c_last_name,
        COUNT(DISTINCT rs.ws_order_number) AS TotalOrders,
        SUM(rs.ws_ext_sales_price) AS TotalSales,
        SUM(CASE WHEN rs.SalesRank = 1 THEN 1 ELSE 0 END) AS TopItemPurchases
    FROM 
        CustomerInfo ci 
    JOIN 
        RankedSales rs ON ci.c_customer_sk = rs.ws_item_sk
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name
)
SELECT 
    ss.c_customer_sk,
    ss.c_first_name,
    ss.c_last_name,
    ss.TotalOrders,
    ss.TotalSales,
    COALESCE(ss.TopItemPurchases, 0) AS TopItemPurchases,
    RANK() OVER (ORDER BY ss.TotalSales DESC) AS SalesRank
FROM 
    SalesSummary ss
WHERE 
    ss.TotalSales > (SELECT AVG(TotalSales) FROM SalesSummary) 
    OR 
    NOT EXISTS (SELECT 1 FROM web_returns wr WHERE wr.wr_returning_customer_sk = ss.c_customer_sk)
ORDER BY 
    ss.TotalSales DESC
LIMIT 10;
