
WITH Address_Concat AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, COALESCE(ca_suite_number, '')) AS full_address
    FROM 
        customer_address
),
Demographic_Concat AS (
    SELECT 
        cd_demo_sk,
        CONCAT(cd_gender, ' ', cd_marital_status, ' ', cd_education_status) AS demographic_info
    FROM 
        customer_demographics
),
Order_Summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ac.full_address,
    dc.demographic_info,
    os.total_orders,
    os.total_spent
FROM 
    customer c
JOIN 
    Address_Concat ac ON c.c_current_addr_sk = ac.ca_address_sk
JOIN 
    Demographic_Concat dc ON c.c_current_cdemo_sk = dc.cd_demo_sk
LEFT JOIN 
    Order_Summary os ON c.c_customer_sk = os.ws_bill_customer_sk
WHERE 
    c.c_preferred_cust_flag = 'Y' 
ORDER BY 
    os.total_spent DESC
LIMIT 100;
