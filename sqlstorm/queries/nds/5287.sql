
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_web_page_sk) AS unique_web_pages
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
Demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cs.c_customer_id,
    cs.total_web_sales,
    cs.total_orders,
    cs.unique_web_pages,
    ws.total_sales AS warehouse_sales,
    d.cd_gender,
    d.cd_marital_status,
    d.avg_purchase_estimate
FROM 
    CustomerSales cs
JOIN 
    WarehouseSales ws ON cs.total_web_sales > 1000
JOIN 
    Demographics d ON cs.total_orders > 5
WHERE 
    cs.total_web_sales > 5000
ORDER BY 
    cs.total_web_sales DESC, ws.total_sales DESC;
