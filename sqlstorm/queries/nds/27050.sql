
WITH AddressInfo AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city, 
        ca_state,
        LENGTH(ca_zip) AS zip_length,
        TRIM(ca_country) AS country
    FROM 
        customer_address
    WHERE 
        ca_state IN ('NY', 'CA')
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        a.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN 
        AddressInfo a ON c.c_current_addr_sk = a.ca_address_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
    GROUP BY 
        ws.ws_bill_customer_sk
),
FinalMetrics AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.full_address,
        COALESCE(si.total_sales, 0) AS total_sales,
        COALESCE(si.order_count, 0) AS order_count,
        CASE 
            WHEN COALESCE(si.total_sales, 0) = 0 THEN 'No Sales'
            ELSE 'Regular Customer'
        END AS customer_type
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesInfo si ON cd.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    fm.*,
    CONCAT(fm.c_first_name, ' ', fm.c_last_name) AS full_name,
    UPPER(fm.cd_gender) AS gender,
    CASE 
        WHEN fm.order_count > 5 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS buying_category
FROM 
    FinalMetrics fm
ORDER BY 
    fm.total_sales DESC, 
    full_name;
