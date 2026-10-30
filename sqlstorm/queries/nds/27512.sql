
WITH ProcessedAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN CONCAT(' Suite ', TRIM(ca_suite_number)) ELSE '' END) AS FullAddress,
        UPPER(TRIM(ca_city)) AS UpperCity,
        LOWER(TRIM(ca_state)) AS LowerState
    FROM customer_address
),
CustomerCounts AS (
    SELECT 
        cd_gender,
        COUNT(*) AS TotalCustomers
    FROM customer 
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_gender
),
ReturnReasons AS (
    SELECT 
        r_reason_desc,
        COUNT(cr_returned_date_sk) AS TotalReturns
    FROM catalog_returns
    JOIN reason ON cr_reason_sk = r_reason_sk
    GROUP BY r_reason_desc
),
WebSalesSummary AS (
    SELECT 
        SUM(ws_quantity) AS TotalQuantitySold,
        SUM(ws_sales_price) AS TotalSales
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
)
SELECT 
    pa.FullAddress,
    pa.UpperCity,
    pa.LowerState,
    cc.TotalCustomers,
    rr.TotalReturns,
    ws.TotalQuantitySold,
    ws.TotalSales
FROM ProcessedAddresses pa
JOIN CustomerCounts cc ON cc.TotalCustomers > 100
JOIN ReturnReasons rr ON rr.TotalReturns > 50
CROSS JOIN WebSalesSummary ws
ORDER BY pa.FullAddress, cc.TotalCustomers DESC, rr.TotalReturns DESC;
