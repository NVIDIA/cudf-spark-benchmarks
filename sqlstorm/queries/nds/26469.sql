
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
PurchaseStats AS (
    SELECT 
        ci.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent,
        AVG(ws.ws_sales_price) AS average_order_value
    FROM 
        CustomerInfo ci
    JOIN 
        web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ci.c_customer_sk
),
TopCustomers AS (
    SELECT 
        ci.c_first_name,
        ci.c_last_name,
        ci.c_email_address,
        ps.total_orders,
        ps.total_spent,
        ps.average_order_value,
        DENSE_RANK() OVER (ORDER BY ps.total_spent DESC) AS rank_position
    FROM 
        CustomerInfo ci
    JOIN 
        PurchaseStats ps ON ci.c_customer_sk = ps.c_customer_sk
)
SELECT 
    rank_position,
    c_first_name,
    c_last_name,
    c_email_address,
    total_orders,
    total_spent,
    average_order_value
FROM 
    TopCustomers
WHERE 
    rank_position <= 10
ORDER BY 
    total_spent DESC;
