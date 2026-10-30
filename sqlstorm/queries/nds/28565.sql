
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address
    FROM customer_address
),
CustomerGenderStats AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS total_customers,
        STRING_AGG(CAST(ca_address_sk AS STRING), ', ') AS address_ids
    FROM customer 
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    JOIN AddressDetails ON c_current_addr_sk = ca_address_sk
    GROUP BY cd_gender
),
SalesPerformance AS (
    SELECT 
        d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        STRING_AGG(DISTINCT CAST(ws_web_page_sk AS STRING), ', ') AS page_ids
    FROM web_sales 
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY d_year
)
SELECT 
    g.cd_gender,
    g.total_customers,
    g.address_ids,
    s.d_year,
    s.total_sales,
    s.page_ids
FROM CustomerGenderStats g
JOIN SalesPerformance s ON g.cd_gender = CASE 
                                            WHEN s.total_sales > 1000000 THEN 'M'
                                            ELSE 'F'
                                          END
ORDER BY s.total_sales DESC;
