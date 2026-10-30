
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
),
DailySales AS (
    SELECT 
        d.d_date_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_date_id
),
TopSalesDays AS (
    SELECT 
        d.d_date_id,
        ds.total_sales,
        ds.total_orders,
        DENSE_RANK() OVER (ORDER BY ds.total_sales DESC) AS sales_rank
    FROM 
        DailySales ds
    JOIN 
        date_dim d ON ds.d_date_id = d.d_date_id
)
SELECT 
    rc.full_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_education_status,
    tsd.d_date_id,
    tsd.total_sales,
    tsd.total_orders
FROM 
    RankedCustomers rc
JOIN 
    TopSalesDays tsd ON rc.rank <= 10
ORDER BY 
    tsd.total_sales DESC, rc.full_name;
