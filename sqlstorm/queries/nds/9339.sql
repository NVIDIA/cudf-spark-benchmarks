
WITH SalesData AS (
    SELECT 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_sales_price) AS avg_sales_price,
        CAST(d.d_date AS DATE) AS sales_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year = 2023 AND cd.cd_gender = 'M'
    GROUP BY 
        CAST(d.d_date AS DATE)
),
InventoryData AS (
    SELECT 
        SUM(inv_quantity_on_hand) AS total_inventory,
        i.i_item_id
    FROM 
        inventory inv
    JOIN 
        item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id
)
SELECT 
    sd.sales_date,
    sd.total_sales,
    sd.order_count,
    sd.avg_sales_price,
    id.total_inventory
FROM 
    SalesData sd
LEFT JOIN 
    InventoryData id ON id.i_item_id IN (SELECT DISTINCT i.i_item_id FROM item i)
ORDER BY 
    sd.sales_date DESC
LIMIT 100;
