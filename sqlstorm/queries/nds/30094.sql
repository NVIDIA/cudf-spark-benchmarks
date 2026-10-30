
WITH  RevenueCTE AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid) AS total_revenue,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
    HAVING 
        SUM(ws_net_paid) > 1000
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(ra.total_revenue, 0) AS total_revenue,
        ra.order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        RevenueCTE ra ON c.c_customer_sk = ra.customer_sk
),
MaxRevenue AS (
    SELECT 
        MAX(total_revenue) AS max_revenue
    FROM 
        HighValueCustomers
),
FilteredCustomers AS (
    SELECT 
        *,
        CASE 
            WHEN total_revenue IS NULL THEN 'New Customer'
            WHEN total_revenue > (SELECT max_revenue FROM MaxRevenue) * 0.75 THEN 'High Value'
            ELSE 'Regular'
        END AS customer_status
    FROM 
        HighValueCustomers
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.total_revenue,
    hvc.order_count,
    hvc.customer_status,
    ca.ca_city,
    ca.ca_state,
    SUM(CASE WHEN ws.ws_item_sk IS NOT NULL THEN 1 ELSE 0 END) AS total_purchases
FROM 
    FilteredCustomers hvc
LEFT JOIN 
    customer_address ca ON hvc.c_customer_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON hvc.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_state IS NOT NULL
GROUP BY 
    hvc.c_first_name, hvc.c_last_name, hvc.cd_gender, 
    hvc.cd_marital_status, hvc.total_revenue, hvc.order_count, 
    hvc.customer_status, ca.ca_city, ca.ca_state
ORDER BY 
    hvc.total_revenue DESC
LIMIT 100;
