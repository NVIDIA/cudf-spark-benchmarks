WITH CustomerStats AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        AVG(i.i_current_price) AS avg_item_price
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2458857 AND 2458941  
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS warehouse_sales
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
StoreSales AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_ext_sales_price) AS store_sales
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_id
)
SELECT 
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_sales,
    cs.customer_count,
    ws.warehouse_sales,
    ss.store_sales,
    cs.avg_item_price
FROM 
    CustomerStats cs
LEFT JOIN 
    WarehouseSales ws ON cs.total_sales > 1000  
LEFT JOIN 
    StoreSales ss ON cs.total_sales > 500  
ORDER BY 
    cs.total_sales DESC, 
    cs.customer_count DESC;