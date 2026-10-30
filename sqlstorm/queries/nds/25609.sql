
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        ca_street_name,
        ca_street_type,
        ca_city,
        ca_state,
        ca_zip,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        d.d_date AS registration_date,
        a.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON c.c_first_shipto_date_sk = d.d_date_sk
    JOIN 
        AddressParts a ON c.c_current_addr_sk = a.ca_address_sk
),
OrderedSales AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.registration_date,
        cd.full_address,
        os.total_orders,
        os.total_sales
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        OrderedSales os ON cd.c_customer_sk = os.ws_bill_customer_sk
)

SELECT 
    c.c_first_name,
    c.c_last_name,
    c.full_address,
    c.total_orders,
    c.total_sales,
    CAST(CONCAT(c.cd_gender, '-', c.cd_marital_status) AS CHAR(20)) AS gender_marital_status
FROM 
    CombinedData c
WHERE 
    c.total_orders > 0
ORDER BY 
    c.total_sales DESC
LIMIT 10;
