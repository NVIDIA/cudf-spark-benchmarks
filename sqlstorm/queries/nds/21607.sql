
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS TotalSales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS SalesRank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS Gender,
        cd_marital_status,
        cd_education_status,
        COALESCE(NULLIF(cd_credit_rating, ''), 'Unknown') AS CreditRating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesWithInfo AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.Gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.CreditRating,
        ci.cd_dep_count,
        ci.cd_dep_employed_count,
        ci.cd_dep_college_count,
        rs.TotalSales
    FROM 
        CustomerInfo ci
        JOIN RankedSales rs ON ci.c_customer_sk = rs.ws_bill_customer_sk
    WHERE 
        rs.SalesRank <= 5
),
FilteredSales AS (
    SELECT 
        *,
        CASE 
            WHEN TotalSales IS NULL THEN 0
            ELSE ROUND(TotalSales / NULLIF(cd_dep_count, 0), 2)
        END AS SalesPerDependents
    FROM 
        SalesWithInfo
)
SELECT 
    f.c_customer_sk,
    CONCAT(f.c_first_name, ' ', f.c_last_name) AS FullName,
    f.Gender,
    f.cd_marital_status,
    f.cd_education_status,
    f.CreditRating,
    f.TotalSales,
    f.SalesPerDependents,
    DENSE_RANK() OVER (ORDER BY f.TotalSales DESC) AS SalesRank,
    f.cd_dep_employed_count,
    f.cd_dep_college_count
FROM 
    FilteredSales f
WHERE 
    f.SalesPerDependents > (SELECT AVG(SalesPerDependents) FROM FilteredSales WHERE SalesPerDependents IS NOT NULL)
ORDER BY 
    TotalSales DESC;
