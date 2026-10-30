
WITH CustomerFullNames AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name
    FROM 
        customer c
    WHERE 
        c.c_first_name IS NOT NULL AND 
        c.c_last_name IS NOT NULL
),
SalesData AS (
    SELECT 
        CASE 
            WHEN ws.ws_ship_date_sk IS NOT NULL THEN 'Web Sales'
            WHEN cs.cs_ship_date_sk IS NOT NULL THEN 'Catalog Sales'
            ELSE 'Store Sales'
        END AS sales_type,
        COALESCE(ws.ws_sales_price, cs.cs_sales_price, ss.ss_sales_price) AS sale_amount,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        web_sales ws
        FULL OUTER JOIN catalog_sales cs ON ws.ws_order_number = cs.cs_order_number
        FULL OUTER JOIN store_sales ss ON ws.ws_order_number = ss.ss_ticket_number
        JOIN customer c ON COALESCE(ws.ws_bill_customer_sk, cs.cs_bill_customer_sk, ss.ss_customer_sk) = c.c_customer_sk
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    sales_type,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    COUNT(*) AS total_sales,
    AVG(sale_amount) AS avg_sale_amount,
    SUM(sale_amount) AS total_revenue
FROM 
    SalesData
GROUP BY 
    sales_type, cd_gender, cd_marital_status, cd_education_status
ORDER BY 
    sales_type, total_sales DESC;
