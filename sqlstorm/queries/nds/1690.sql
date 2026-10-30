
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sales_price DESC) AS SaleRank
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 100
), 
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
SalesSummary AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_sales_price) AS TotalSales,
        COUNT(ws.ws_item_sk) AS TotalItems,
        AVG(ws.ws_sales_price) AS AvgSalePrice
    FROM 
        web_sales ws
    JOIN 
        CustomerInfo c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        SUM(ws.ws_sales_price) > 500
)
SELECT 
    ci.c_first_name, 
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_credit_rating,
    ss.TotalSales, 
    ss.TotalItems,
    ss.AvgSalePrice,
    COUNT(DISTINCT rs.ws_item_sk) AS DistinctItemsRanked
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesSummary ss ON ci.c_customer_sk = ss.c_customer_sk
LEFT JOIN 
    RankedSales rs ON ci.c_customer_sk = rs.ws_bill_customer_sk
WHERE 
    (ci.cd_gender = 'F' AND ci.cd_marital_status = 'M') 
    OR (ci.cd_gender = 'M' AND ci.cd_credit_rating = 'Good')
GROUP BY 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ci.cd_credit_rating, 
    ss.TotalSales, 
    ss.TotalItems, 
    ss.AvgSalePrice
ORDER BY 
    ss.TotalSales DESC 
LIMIT 10;
