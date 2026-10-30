
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT CASE WHEN ws.ws_ship_date_sk IS NOT NULL THEN ws.ws_order_number END) AS fulfilled_orders,
        COUNT(DISTINCT CASE WHEN ws.ws_ship_date_sk IS NULL THEN ws.ws_order_number END) AS unfulfilled_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(cd.cd_demo_sk) AS demographic_count
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_purchase_estimate > 10000
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
), 
WarehouseSummary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        warehouse w
    LEFT JOIN 
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    cs.c_customer_id,
    cs.total_web_sales,
    cs.total_orders,
    cs.fulfilled_orders,
    cs.unfulfilled_orders,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.demographic_count,
    ws.w_warehouse_id,
    ws.total_inventory,
    CASE 
        WHEN cs.total_web_sales IS NULL THEN 'No Sales'
        WHEN cs.total_web_sales < 1000 THEN 'Low Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM 
    CustomerSales cs
FULL OUTER JOIN 
    CustomerDemographics cd ON cs.total_orders = cd.demographic_count
FULL OUTER JOIN 
    WarehouseSummary ws ON cs.total_orders % 2 = 0 AND cd.demographic_count > 5
WHERE 
    (cs.total_web_sales IS NOT NULL OR cd.cd_gender IS NOT NULL)
    AND (ws.total_inventory IS NULL OR ws.total_inventory > 500)
ORDER BY 
    CASE WHEN cs.total_web_sales IS NULL THEN 1 ELSE 0 END,
    cs.total_web_sales DESC,
    cd.cd_marital_status DESC;
