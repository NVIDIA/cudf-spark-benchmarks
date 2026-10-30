
WITH customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
address_summary AS (
    SELECT 
        cga.ca_city,
        cga.ca_state,
        COUNT(DISTINCT cs.c_customer_id) AS customer_count,
        SUM(cs.total_sales) AS total_sales_by_city
    FROM 
        customer_address cga
    JOIN 
        customer c ON c.c_current_addr_sk = cga.ca_address_sk
    JOIN 
        customer_summary cs ON c.c_customer_id = cs.c_customer_id
    GROUP BY 
        cga.ca_city, cga.ca_state
),
zipcode_summary AS (
    SELECT 
        cga.ca_zip,
        COUNT(DISTINCT cga.ca_address_sk) AS address_count,
        SUM(asbs.total_sales_by_city) AS total_sales_by_zip
    FROM 
        customer_address cga
    JOIN 
        address_summary asbs ON cga.ca_city = asbs.ca_city AND cga.ca_state = asbs.ca_state
    GROUP BY 
        cga.ca_zip
)
SELECT 
    zs.ca_zip,
    zs.address_count,
    zs.total_sales_by_zip
FROM 
    zipcode_summary zs
WHERE 
    zs.total_sales_by_zip > 10000
ORDER BY 
    zs.total_sales_by_zip DESC
LIMIT 10;
