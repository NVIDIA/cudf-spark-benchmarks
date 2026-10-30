
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as RowNum
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id, 
        cs.c_first_name, 
        cs.c_last_name, 
        cs.cd_gender, 
        cs.cd_marital_status, 
        cs.cd_purchase_estimate
    FROM 
        CustomerSummary cs
    WHERE 
        cs.RowNum <= 10
),
WarehouseInventory AS (
    SELECT 
        i.i_item_id, 
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        item i
    JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY 
        i.i_item_id
),
SalesData AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_sales_price) AS total_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
ReturnsData AS (
    SELECT 
        sr.sr_item_sk, 
        SUM(sr.sr_return_quantity) AS total_returns
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_item_sk
),
FinalReport AS (
    SELECT 
        tc.c_customer_id, 
        tc.c_first_name, 
        tc.c_last_name,
        wi.total_quantity,
        COALESCE(sd.total_sales_price, 0) AS total_sales_price,
        COALESCE(rd.total_returns, 0) AS total_returns,
        (COALESCE(sd.total_sales_price, 0) - COALESCE(rd.total_returns, 0)) AS net_sales
    FROM 
        TopCustomers tc
    LEFT JOIN 
        WarehouseInventory wi ON wi.i_item_id = (SELECT i.i_item_id FROM item i LIMIT 1)  
    LEFT JOIN 
        SalesData sd ON sd.ws_item_sk = (SELECT MIN(ws_item_sk) FROM web_sales)  
    LEFT JOIN 
        ReturnsData rd ON rd.sr_item_sk = (SELECT MIN(sr_item_sk) FROM store_returns)  
)
SELECT 
    fr.c_customer_id, 
    fr.c_first_name, 
    fr.c_last_name,
    fr.total_quantity,
    fr.total_sales_price,
    fr.total_returns,
    fr.net_sales,
    CASE 
        WHEN fr.net_sales > 1000 THEN 'High Value'
        WHEN fr.net_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS sales_category
FROM 
    FinalReport fr
ORDER BY 
    fr.net_sales DESC
LIMIT 50;
