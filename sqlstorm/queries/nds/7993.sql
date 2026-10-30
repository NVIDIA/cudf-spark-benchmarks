
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
    GROUP BY 
        ws.ws_sold_date_sk
),
CustomerData AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        AVG(cd.cd_dep_count) AS avg_dependents
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    d.d_date AS sales_date,
    s.total_quantity,
    s.total_sales,
    s.total_orders,
    c.customer_count,
    c.avg_purchase_estimate,
    c.avg_dependents
FROM 
    SalesData s
JOIN 
    date_dim d ON s.ws_sold_date_sk = d.d_date_sk
JOIN 
    CustomerData c ON c.customer_count > 0
ORDER BY 
    d.d_date;
