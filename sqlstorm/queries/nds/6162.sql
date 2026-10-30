
WITH CustomerStats AS (
    SELECT 
        cd.cd_gender,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' AND 
        ca.ca_country = 'USA'
    GROUP BY 
        cd.cd_gender, ca.ca_state
), 
WarehouseSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS warehouse_sales
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
), 
DailySales AS (
    SELECT 
        d.d_date_id,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales
    FROM 
        date_dim d
    LEFT JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date_id
)
SELECT 
    cs.cd_gender,
    cs.ca_state,
    cs.customer_count,
    cs.total_sales,
    ws.warehouse_sales,
    ds.d_date_id,
    ds.total_catalog_sales,
    ds.total_web_sales
FROM 
    CustomerStats cs
JOIN 
    WarehouseSales ws ON 1=1
JOIN 
    DailySales ds ON ds.d_date_id = (SELECT MAX(d.d_date_id) FROM date_dim d)
ORDER BY 
    cs.cd_gender, cs.ca_state;
