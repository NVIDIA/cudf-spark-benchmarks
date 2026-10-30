
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_web_site_sk,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_web_site_sk ORDER BY ws_sales_price DESC) AS SalesRank
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
CustomerStats AS (
    SELECT 
        cd_demo_sk,
        AVG(cd_purchase_estimate) AS AvgPurchaseEstimate,
        COUNT(DISTINCT c_customer_sk) AS CustomerCount
    FROM 
        customer_demographics
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk
),
HighValueCustomers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        (SELECT COUNT(sr_ticket_number) 
         FROM store_returns 
         WHERE sr_customer_sk = c_customer_sk) AS ReturnCount,
        (SELECT COUNT(wr_order_number) 
         FROM web_returns 
         WHERE wr_returning_customer_sk = c_customer_sk) AS WebReturnCount
    FROM 
        customer
    WHERE 
        c_first_shipto_date_sk IS NOT NULL
    AND 
        c_last_review_date_sk IS NULL
),
FinalResults AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.c_first_name,
        hvc.c_last_name,
        cs.AvgPurchaseEstimate,
        rk.ws_sales_price,
        rk.SalesRank
    FROM 
        HighValueCustomers hvc
    LEFT JOIN 
        CustomerStats cs ON hvc.c_customer_sk = cs.cd_demo_sk
    LEFT JOIN 
        RankedSales rk ON rk.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_current_price > 50)
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    COALESCE(f.AvgPurchaseEstimate, 0) AS AvgPurchaseEstimate,
    ROUND(SUM(f.ws_sales_price - f.ws_sales_price * 0.1), 2) AS TotalDiscountedSales,
    COUNT(DISTINCT f.ws_sales_price) AS UniqueSaleCounts,
    (CASE 
        WHEN SUM(f.ws_sales_price) > 1000 THEN 'High Value'
        ELSE 'Low Value' 
     END) AS ValueCategory
FROM 
    FinalResults f
WHERE 
    f.ws_sales_price IS NOT NULL
GROUP BY 
    f.c_customer_sk, f.c_first_name, f.c_last_name, f.AvgPurchaseEstimate
HAVING 
    COUNT(f.ws_sales_price) FILTER (WHERE f.ws_sales_price IS NOT NULL) > 5
ORDER BY 
    TotalDiscountedSales DESC, f.c_last_name ASC
LIMIT 100 OFFSET 10;
