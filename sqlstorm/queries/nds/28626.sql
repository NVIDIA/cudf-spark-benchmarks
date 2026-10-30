
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        CONCAT(c.c_first_name, ' ', c.c_last_name, ' - ', ca.ca_city, ', ', ca.ca_state) AS detailed_info
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_paid) AS avg_spent_per_order
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
InventoryDetails AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    ci.cd_marital_status,
    si.total_spent,
    si.order_count,
    si.avg_spent_per_order,
    CASE
        WHEN si.total_spent IS NULL THEN 'No purchases'
        ELSE 'Purchased'
    END AS purchase_status,
    id.total_inventory
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
LEFT JOIN 
    InventoryDetails id ON id.inv_item_sk = si.ws_bill_customer_sk
WHERE 
    ci.cd_gender = 'F'
ORDER BY 
    ci.ca_city, total_spent DESC;
