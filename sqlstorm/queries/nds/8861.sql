
WITH SalesData AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        w.w_warehouse_id
),
CustomerData AS (
    SELECT 
        cd.cd_gender,
        SUM(CASE WHEN cs.cs_quantity IS NOT NULL THEN cs.cs_quantity ELSE 0 END) AS total_quantity,
        SUM(CASE WHEN cs.cs_sales_price IS NOT NULL THEN cs.cs_sales_price ELSE 0 END) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M'
    GROUP BY 
        cd.cd_gender
)
SELECT 
    sd.w_warehouse_id,
    sd.total_quantity,
    sd.total_sales,
    sd.order_count,
    sd.avg_net_profit,
    cd.cd_gender,
    cd.total_quantity AS customer_total_quantity,
    cd.total_sales AS customer_total_sales
FROM 
    SalesData sd
JOIN 
    CustomerData cd ON sd.total_quantity > 1000
ORDER BY 
    sd.total_sales DESC, 
    cd.cd_gender;
