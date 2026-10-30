
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate, 
        cd.cd_credit_rating, 
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
SalesSummary AS (
    SELECT 
        ws.ws_ship_date_sk, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_net_paid_inc_tax) AS total_sales, 
        ROW_NUMBER() OVER (PARTITION BY ws.ws_ship_date_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rn
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_date_sk
), 
TopSales AS (
    SELECT 
        s.ws_ship_date_sk, 
        s.total_quantity, 
        s.total_sales
    FROM 
        SalesSummary s
    WHERE 
        s.rn <= 10
), 
InventoryCheck AS (
    SELECT 
        i.inv_item_sk, 
        SUM(i.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory i
    GROUP BY 
        i.inv_item_sk
)
SELECT 
    ci.c_customer_id,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    ts.total_quantity,
    ts.total_sales,
    COALESCE(ic.total_inventory, 0) AS available_inventory,
    CASE 
        WHEN ts.total_sales > 1000 THEN 'High Value'
        ELSE 'Low Value'
    END AS value_category
FROM 
    CustomerInfo ci
LEFT JOIN 
    TopSales ts ON ci.c_customer_sk = ts.ws_ship_date_sk
LEFT JOIN 
    InventoryCheck ic ON ts.total_quantity IS NOT NULL
ORDER BY 
    ci.c_customer_id, 
    ts.total_sales DESC;
