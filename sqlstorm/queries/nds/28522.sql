
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        c.c_email_address,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
PurchaseDetails AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count,
        MAX(date_dim.d_date) AS last_purchase_date
    FROM 
        web_sales ws
    JOIN 
        date_dim ON ws.ws_sold_date_sk = date_dim.d_date_sk
    GROUP BY 
        ws.ws_bill_customer_sk
),
CombinedInfo AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.c_email_address,
        ci.ca_city,
        ci.ca_state,
        pd.total_spent,
        pd.order_count,
        pd.last_purchase_date
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        PurchaseDetails pd ON ci.c_customer_sk = pd.ws_bill_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_spent IS NULL THEN 'No Purchases'
        WHEN total_spent < 100 THEN 'Low Value Customer'
        WHEN total_spent BETWEEN 100 AND 500 THEN 'Medium Value Customer'
        ELSE 'High Value Customer' 
    END AS customer_value_category
FROM 
    CombinedInfo
ORDER BY 
    total_spent DESC NULLS LAST, 
    full_name;
