
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rnk
    FROM 
        web_sales ws 
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        w.web_country = 'United States' 
        AND ws.ws_sales_price IS NOT NULL
),
HighSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_sales_price) AS total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.rnk = 1
    GROUP BY 
        rs.ws_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_count,
        cd.cd_credit_rating,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
            WHEN cd.cd_purchase_estimate < 10000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 10000 AND 50000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_category
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesStats AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name || ' ' || ci.c_last_name AS full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_dep_count,
        ci.purchase_category,
        hs.total_sales
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        HighSales hs ON ci.c_customer_sk = hs.ws_item_sk
),
FinalReport AS (
    SELECT 
        ss.c_customer_sk,
        ss.full_name,
        ss.cd_gender,
        ss.cd_marital_status,
        ss.cd_dep_count,
        ss.purchase_category,
        COALESCE(ss.total_sales, 0) AS total_sales,
        CASE 
            WHEN COALESCE(ss.total_sales, 0) > 100000 THEN 'VIP' 
            WHEN COALESCE(ss.total_sales, 0) BETWEEN 50000 AND 100000 THEN 'Regular' 
            ELSE 'New Customer' 
        END AS customer_status
    FROM 
        SalesStats ss
)
SELECT 
    fr.full_name, 
    fr.cd_gender, 
    fr.cd_marital_status,
    fr.cd_dep_count,
    fr.purchase_category,
    fr.total_sales,
    fr.customer_status,
    (SELECT COUNT(*) 
     FROM customer c 
     WHERE c.c_birth_year = EXTRACT(YEAR FROM DATE '2002-10-01') - (EXTRACT(YEAR FROM DATE '2002-10-01') - marg.c_birth_year)) AS current_year_births 
FROM 
    FinalReport fr
LEFT JOIN 
    (SELECT DISTINCT c_birth_year
     FROM customer
     WHERE c_birth_year IS NOT NULL) AS marg ON marg.c_birth_year = EXTRACT(YEAR FROM DATE '2002-10-01') - (EXTRACT(YEAR FROM DATE '2002-10-01') - 18)
WHERE 
    fr.total_sales IS NOT NULL
ORDER BY 
    fr.total_sales DESC
LIMIT 100;
