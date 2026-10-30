WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        d.d_year
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = (SELECT MAX(d_year) FROM date_dim) 
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, d.d_year
),

DemographicStats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(*) AS num_customers,
        AVG(total_sales) AS avg_sales
    FROM 
        CustomerSales
    GROUP BY 
        cd_gender, cd_marital_status, cd_education_status
)

SELECT 
    ds.cd_gender,
    ds.cd_marital_status,
    ds.cd_education_status,
    ds.num_customers,
    ds.avg_sales,
    RANK() OVER (ORDER BY ds.avg_sales DESC) AS sales_rank
FROM 
    DemographicStats ds
WHERE 
    ds.num_customers > 10 
ORDER BY 
    ds.avg_sales DESC;