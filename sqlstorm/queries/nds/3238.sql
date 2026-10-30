
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesAnalytics AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.ca_city,
        cd.ca_state,
        COALESCE(rs.total_sales, 0) AS total_sales,
        CASE 
            WHEN COALESCE(rs.total_sales, 0) = 0 THEN 'No Sales'
            ELSE 'Has Sales'
        END AS sales_status
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        RankedSales rs ON cd.c_customer_sk = rs.ws_bill_customer_sk
)
SELECT 
    s.c_first_name,
    s.c_last_name,
    COUNT(DISTINCT s.c_customer_sk) AS unique_customers,
    SUM(s.total_sales) AS overall_sales,
    AVG(s.total_sales) AS average_sales,
    MAX(s.total_sales) AS maximum_sales,
    MIN(s.total_sales) AS minimum_sales,
    STRING_AGG(s.sales_status, ', ') AS sales_status_summary
FROM 
    SalesAnalytics s
WHERE 
    s.ca_city IS NOT NULL AND 
    s.ca_state IN ('NY', 'CA') AND 
    (s.total_sales > 1000 OR s.sales_status = 'No Sales')
GROUP BY 
    s.c_first_name, 
    s.c_last_name
HAVING 
    COUNT(DISTINCT s.c_customer_sk) > 1
ORDER BY 
    overall_sales DESC
LIMIT 5 OFFSET 10;
