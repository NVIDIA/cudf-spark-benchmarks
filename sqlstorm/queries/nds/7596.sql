
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(d.d_date) AS last_purchase_date,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT cs.c_customer_id) AS num_customers,
        AVG(cs.total_sales) AS avg_sales,
        AVG(cs.total_orders) AS avg_orders,
        MAX(cs.last_purchase_date) AS last_purchase_date
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.cd_gender = cd.cd_gender AND cs.cd_marital_status = cd.cd_marital_status
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.num_customers,
    cd.avg_sales,
    cd.avg_orders,
    cd.last_purchase_date
FROM 
    CustomerDemographics cd
ORDER BY 
    cd.cd_gender, cd.cd_marital_status;
