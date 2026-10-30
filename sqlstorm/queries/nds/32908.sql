
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
    HAVING 
        SUM(ws_ext_sales_price) > 0
), Demographics AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
), NullCheck AS (
    SELECT
        ca_state,
        COUNT(*) AS address_count
    FROM
        customer_address
    WHERE
        ca_city IS NULL OR ca_zip IS NULL
    GROUP BY
        ca_state
)
SELECT 
    d.d_date AS Sale_Date,
    d.d_year AS Year, 
    COALESCE(demo.cd_gender, 'Unknown') AS Gender,
    s.total_sales AS Total_Sales,
    n.address_count AS Null_Address_Count
FROM 
    date_dim d
LEFT JOIN 
    SalesCTE s ON d.d_date_sk = s.ws_sold_date_sk
LEFT JOIN 
    Demographics demo ON d.d_year = EXTRACT(YEAR FROM DATE '2002-10-01') 
LEFT JOIN 
    NullCheck n ON n.ca_state = 'CA'
WHERE 
    d.d_year IN (SELECT DISTINCT d_year FROM date_dim WHERE d_current_year = '1')
ORDER BY 
    d.d_date
LIMIT 1000;
