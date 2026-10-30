
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
RevenueByDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cs.total_sales) AS demographic_revenue,
        COUNT(DISTINCT cs.c_customer_sk) AS customer_count
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
TopDemographics AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY demographic_revenue DESC) AS revenue_rank
    FROM 
        RevenueByDemographics
)
SELECT 
    td.cd_gender,
    td.cd_marital_status,
    td.demographic_revenue,
    td.customer_count
FROM 
    TopDemographics td
WHERE 
    td.revenue_rank <= 5
ORDER BY 
    td.demographic_revenue DESC;
