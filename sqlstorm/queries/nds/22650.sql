
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
TopCustomers AS (
    SELECT 
        c_customer_id, 
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM 
        RankedCustomers
    WHERE 
        rnk <= 10
),
SalesData AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        sd.total_sales,
        sd.total_quantity,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        item i
    LEFT JOIN 
        SalesData sd ON i.i_item_sk = sd.ws_item_sk
)
SELECT 
    tc.c_customer_id,
    tc.cd_gender,
    tc.cd_marital_status,
    SUM(id.total_sales) AS total_sales,
    SUM(id.total_quantity) AS total_quantity,
    MAX(COALESCE(id.i_current_price, 0)) AS max_price,
    STRING_AGG(id.i_product_name || ' (' || COALESCE(CAST(id.total_quantity AS STRING), '0') || ' sold)', ', ') AS products_sold,
    CASE 
        WHEN COUNT(NULLIF(id.i_product_name, '')) = 0 THEN 'No Products Sold'
        ELSE 'Products Sold'
    END AS sale_status
FROM 
    TopCustomers tc
LEFT JOIN 
    ItemDetails id ON tc.c_customer_id = id.i_item_id
GROUP BY 
    tc.c_customer_id, tc.cd_gender, tc.cd_marital_status
HAVING 
    SUM(id.total_sales) > 1000 OR COUNT(DISTINCT id.i_item_id) > 3
ORDER BY 
    total_sales DESC;
