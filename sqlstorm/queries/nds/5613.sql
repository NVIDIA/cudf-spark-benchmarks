
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        COUNT(cd.cd_demo_sk) AS demo_count
    FROM 
        customer_demographics cd
    GROUP BY 
        cd.cd_gender
),
SalesByDemographics AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.total_orders,
        cd.cd_gender
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS total_warehouse_sales
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    cs.c_customer_id,
    cs.total_sales,
    cs.total_orders,
    cd.demo_count AS gender_demo_count,
    ws.total_warehouse_sales
FROM 
    SalesByDemographics cs
JOIN 
    CustomerDemographics cd ON cs.cd_gender = cd.cd_gender
JOIN 
    WarehouseSales ws ON cs.total_sales > 1000
ORDER BY 
    cs.total_sales DESC;
