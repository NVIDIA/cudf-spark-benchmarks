
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, COALESCE(ca_suite_number, '')) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate,
        d.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedInfo AS (
    SELECT 
        concat_ws(', ', cd.full_name, ap.full_address, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status) AS customer_info,
        si.total_sales,
        si.total_orders
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesInfo si ON cd.c_customer_sk = si.ws_bill_customer_sk
    LEFT JOIN 
        AddressParts ap ON cd.c_customer_sk = ap.ca_address_sk
)
SELECT 
    customer_info,
    total_sales,
    total_orders,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM 
    CombinedInfo
WHERE 
    total_sales > 1000
ORDER BY 
    sales_rank;
