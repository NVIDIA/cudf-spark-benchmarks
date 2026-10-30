WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        da.ca_city,
        da.ca_state,
        da.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_address da ON c.c_current_addr_sk = da.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws.ws_web_page_sk,
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_web_page_sk, ws.ws_order_number
),
CombinedData AS (
    SELECT 
        cd.c_customer_id,
        cd.c_first_name,
        cd.c_last_name,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        sd.total_sales,
        sd.avg_discount,
        sd.unique_customers
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesDetails sd ON cd.c_customer_id = CAST(sd.ws_order_number AS CHAR(16))  
)
SELECT 
    ca_state,
    COUNT(*) AS customer_count,
    SUM(total_sales) AS grand_total_sales,
    AVG(avg_discount) AS average_discount,
    COUNT(DISTINCT c_customer_id) AS unique_customers
FROM 
    CombinedData
GROUP BY 
    ca_state
ORDER BY 
    grand_total_sales DESC;