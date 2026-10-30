
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        w.w_warehouse_name,
        cd_gender,
        d.d_year
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        ws_sold_date_sk, w.w_warehouse_name, cd_gender, d.d_year
),
RankedSales AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY w_warehouse_name, d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    w_warehouse_name,
    d_year,
    cd_gender,
    total_quantity,
    total_sales,
    total_orders
FROM 
    RankedSales
WHERE 
    sales_rank <= 5
ORDER BY 
    w_warehouse_name, d_year, sales_rank;
