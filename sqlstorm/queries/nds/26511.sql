
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        ca.ca_city,
        ca.ca_state,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
RecentPurchases AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS purchase_count
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY ws.ws_bill_customer_sk
),
CustomerSpending AS (
    SELECT 
        cd.c_customer_sk,
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        COALESCE(rp.total_spent, 0) AS total_spent,
        COALESCE(rp.purchase_count, 0) AS purchase_count
    FROM CustomerDetails cd
    LEFT JOIN RecentPurchases rp ON cd.c_customer_sk = rp.ws_bill_customer_sk
)
SELECT 
    cs.full_name,
    cs.ca_city,
    cs.ca_state,
    cs.total_spent,
    cs.purchase_count,
    CASE 
        WHEN cs.total_spent > 1000 THEN 'High Value'
        WHEN cs.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM CustomerSpending cs
ORDER BY customer_value_segment DESC, cs.total_spent DESC;
