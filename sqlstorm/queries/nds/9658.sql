
WITH SalesData AS (
    SELECT 
        w.w_warehouse_id, 
        SUM(ws.ws_quantity) AS total_quantity_sold, 
        SUM(ws.ws_sales_price) AS total_sales,
        d.d_year,
        d.d_month_seq,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        w.w_warehouse_id, d.d_year, d.d_month_seq
),
CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_sales_price) AS total_spent, 
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_id
),
DemographicSales AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        customer_demographics cd
    JOIN 
        web_sales ws ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    sd.w_warehouse_id,
    sd.total_quantity_sold,
    sd.total_sales,
    cs.total_spent,
    cs.order_count,
    ds.cd_gender,
    ds.cd_marital_status,
    ds.total_sales AS demographic_sales
FROM 
    SalesData sd
JOIN 
    CustomerSales cs ON cs.total_spent > 100 
JOIN 
    DemographicSales ds ON ds.total_sales > (SELECT AVG(total_sales) FROM DemographicSales)
ORDER BY 
    sd.total_sales DESC, cs.total_spent DESC;
