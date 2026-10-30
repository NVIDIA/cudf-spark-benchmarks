
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_spent,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        sd.total_spent,
        sd.order_count,
        RANK() OVER (ORDER BY sd.total_spent DESC) AS rank
    FROM 
        CustomerDetails cd
    JOIN 
        SalesData sd ON cd.c_customer_sk = sd.customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    total_spent,
    order_count,
    rank
FROM 
    TopCustomers
WHERE 
    rank <= 10
ORDER BY 
    total_spent DESC;
