
WITH  Sales_CTE AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER(PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
Customer_Status AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Address_Join AS (
    SELECT 
        ca.ca_country,
        COUNT(DISTINCT ca.ca_address_sk) AS address_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_country
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs_total.total_quantity,
    cs_total.total_sales,
    address.address_count,
    CASE 
        WHEN cd.cd_marital_status = 'M' THEN 'Married'
        WHEN cd.cd_marital_status = 'S' THEN 'Single'
        ELSE 'Unknown'
    END AS marital_status,
    COALESCE(NULLIF(cs_total.total_quantity, 0), 1) AS adjusted_quantity, 
    ROUND((cs_total.total_sales - cs_total.total_sales * 0.1), 2) AS net_sales_after_discount
FROM 
    Customer_Status cs
JOIN 
    Sales_CTE cs_total ON cs.c_customer_sk = cs_total.ws_bill_customer_sk
JOIN 
    Address_Join address ON cs.c_customer_sk IS NOT NULL
JOIN 
    customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
WHERE 
    cs.gender_rank <= 10
    AND cs_total.total_sales > (
        SELECT AVG(total_sales) FROM Sales_CTE
    )
ORDER BY 
    marital_status DESC,
    net_sales_after_discount DESC
LIMIT 100;
