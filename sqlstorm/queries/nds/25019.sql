
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_customer_sk) AS gender_rank
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), FilteredAddresses AS (
    SELECT 
        ca.ca_address_sk, 
        TRIM(CONCAT_WS(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type)) AS full_address, 
        ca.ca_city, 
        ca.ca_state
    FROM 
        customer_address ca 
    WHERE 
        ca.ca_state IN ('CA', 'TX') 
        AND ca.ca_city IS NOT NULL
), AggregatedSales AS (
    SELECT 
        ws.ws_bill_customer_sk, 
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws 
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    rc.full_name, 
    rc.cd_gender, 
    rc.cd_marital_status, 
    rc.cd_education_status, 
    fa.full_address, 
    fa.ca_city, 
    fa.ca_state, 
    COALESCE(asales.total_sales, 0) AS total_sales
FROM 
    RankedCustomers rc 
JOIN 
    FilteredAddresses fa ON rc.c_customer_sk = fa.ca_address_sk
LEFT JOIN 
    AggregatedSales asales ON rc.c_customer_sk = asales.ws_bill_customer_sk
WHERE 
    rc.gender_rank <= 10 
ORDER BY 
    rc.cd_gender, rc.full_name;
