
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        RANK() OVER (PARTITION BY cd.cd_marital_status ORDER BY c.c_birth_year DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressCounts AS (
    SELECT 
        ca.ca_city,
        COUNT(DISTINCT ca.ca_address_sk) AS address_count
    FROM 
        customer_address ca
    GROUP BY 
        ca.ca_city
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number, ws.ws_item_sk
),
ConsolidatedData AS (
    SELECT 
        rc.c_customer_id,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        ac.address_count,
        sd.total_quantity,
        sd.total_sales,
        rc.rank
    FROM 
        RankedCustomers rc
    LEFT JOIN 
        AddressCounts ac ON rc.c_customer_id = CONCAT('CUST-', ac.address_count)  
    LEFT JOIN 
        SalesData sd ON rc.c_customer_id = CONCAT('ORDER-', sd.ws_order_number)  
)
SELECT 
    CONCAT(c_first_name, ' ', c_last_name) AS full_name,
    cd_gender,
    cd_marital_status,
    COALESCE(address_count, 0) AS total_addresses,
    COALESCE(total_quantity, 0) AS total_items_purchased,
    COALESCE(total_sales, 0) AS total_spent
FROM 
    ConsolidatedData
WHERE 
    rank = 1
ORDER BY 
    total_spent DESC
LIMIT 10;
