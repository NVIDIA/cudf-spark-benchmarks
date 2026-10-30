
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY c.c_birth_year ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_year
),
TopSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales
    FROM 
        CustomerSales cs
    WHERE 
        cs.sales_rank <= 10
),
CustomerAddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        CASE 
            WHEN ca.ca_state IS NULL THEN 'Unknown'
            WHEN ca.ca_state IN ('NY', 'CA', 'TX') THEN 'Major State'
            ELSE 'Other State'
        END AS address_type
    FROM 
        customer_address ca
),
ErrorLog AS (
    SELECT 
        CASE 
            WHEN COALESCE(ts.total_sales, 0) = 0 THEN 'No Sales'
            ELSE 'Sales Recorded'
        END AS sales_status,
        CAD.ca_city,
        CAD.address_type,
        ts.c_customer_sk
    FROM 
        TopSales ts
    LEFT JOIN 
        CustomerAddressDetails CAD ON ts.c_customer_sk = CAD.ca_address_sk
)
SELECT 
    E.sales_status,
    COUNT(DISTINCT E.ca_city) AS unique_cities,
    AVG(COALESCE(ts.total_sales, 0)) AS avg_sales
FROM 
    ErrorLog E
LEFT JOIN 
    TopSales ts ON E.c_customer_sk = ts.c_customer_sk 
GROUP BY 
    E.sales_status
HAVING 
    AVG(COALESCE(ts.total_sales, 0)) > 100
ORDER BY 
    unique_cities DESC, avg_sales DESC
LIMIT 5;
