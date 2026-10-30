
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales,
        ws_web_site_sk
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2022-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2022-12-31')
    GROUP BY 
        ws_item_sk, ws_web_site_sk
),
CustomerData AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
InventoryData AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
)
SELECT 
    s.ws_web_site_sk,
    COUNT(DISTINCT s.ws_item_sk) AS unique_items_sold,
    SUM(s.total_quantity_sold) AS total_quantity_sold,
    SUM(s.total_sales) AS total_sales,
    AVG(cd.cd_purchase_estimate) AS average_purchase_estimate,
    SUM(i.total_inventory) AS total_inventory_on_hand
FROM 
    SalesData s
JOIN 
    CustomerData cd ON s.ws_item_sk = cd.c_customer_sk
JOIN 
    InventoryData i ON s.ws_item_sk = i.inv_item_sk
GROUP BY 
    s.ws_web_site_sk, cd.cd_purchase_estimate
ORDER BY 
    total_sales DESC
LIMIT 10;
