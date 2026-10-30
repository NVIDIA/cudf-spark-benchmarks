
WITH AddressParts AS (
    SELECT
        ca_address_sk,
        ca_street_number,
        ca_street_name,
        ca_street_type,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        TRIM(REPLACE(ca_street_type, 'St', 'Street')) AS normalized_street_type
    FROM
        customer_address
),
SalesData AS (
    SELECT
        ws_bill_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk,
        ws_item_sk
),
CombinedData AS (
    SELECT
        a.ca_address_sk,
        a.full_address,
        s.ws_bill_customer_sk,
        s.total_quantity,
        s.total_net_paid,
        s.order_count
    FROM
        AddressParts a
    LEFT JOIN
        SalesData s ON a.ca_address_sk = s.ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    COALESCE(ca.total_quantity, 0) AS total_purchased_items,
    COALESCE(ca.total_net_paid, 0) AS total_spent,
    CASE 
        WHEN ca.order_count IS NULL THEN 'No Orders' 
        ELSE CONCAT(ca.order_count, ' Orders') 
    END AS order_summary,
    CASE
        WHEN cd.cd_marital_status = 'M' THEN 'Married'
        ELSE 'Single'
    END AS marital_status,
    a.full_address
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    CombinedData ca ON c.c_customer_sk = ca.ws_bill_customer_sk
JOIN 
    AddressParts a ON a.ca_address_sk = c.c_current_addr_sk 
WHERE 
    cd.cd_purchase_estimate > 1000
ORDER BY 
    total_spent DESC
LIMIT 100;
