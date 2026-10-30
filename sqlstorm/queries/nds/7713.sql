
WITH SalesData AS (
    SELECT 
        d.d_date AS sales_date,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        d.d_date
),
CustomerStats AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(sd.total_quantity) AS total_qty,
        SUM(sd.total_sales) AS total_sales,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers
    FROM 
        SalesData sd
    JOIN 
        customer c ON c.c_first_shipto_date_sk IN (SELECT DISTINCT d.d_date_sk FROM date_dim d WHERE d.d_date BETWEEN '2023-01-01' AND '2023-12-31')
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(cs.total_qty) AS total_quantity,
    SUM(cs.total_sales) AS total_sales,
    cs.num_customers,
    ROUND(SUM(cs.total_sales) / NULLIF(cs.num_customers, 0), 2) AS avg_sales_per_customer
FROM 
    CustomerStats cs
JOIN 
    customer_demographics cd ON cs.cd_gender = cd.cd_gender AND cs.cd_marital_status = cd.cd_marital_status
GROUP BY 
    cd.cd_gender, cd.cd_marital_status, cs.num_customers
ORDER BY 
    total_sales DESC, total_quantity DESC;
