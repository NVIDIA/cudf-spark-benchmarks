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
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesByDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cs.total_sales) AS demographic_sales,
        COUNT(cs.c_customer_sk) AS demographic_count
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
SalesByDate AS (
    SELECT 
        dd.d_year,
        dd.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS monthly_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        dd.d_year, dd.d_month_seq
),
CombinedResults AS (
    SELECT 
        sbd.cd_gender,
        sbd.cd_marital_status,
        sbd.demographic_sales,
        sbd.demographic_count,
        sbd.demographic_sales / NULLIF(sbd.demographic_count, 0) AS avg_sales_per_customer,
        sbd.demographic_sales / NULLIF(sd.monthly_sales, 0) AS sales_ratio
    FROM 
        SalesByDemographics sbd
    JOIN 
        SalesByDate sd ON sd.d_year = EXTRACT(YEAR FROM cast('2002-10-01' as date)) AND sd.d_month_seq = EXTRACT(MONTH FROM cast('2002-10-01' as date))
)
SELECT 
    cd_gender,
    cd_marital_status,
    SUM(demographic_sales) AS total_demographic_sales,
    AVG(avg_sales_per_customer) AS avg_sales_per_demographic,
    SUM(demographic_sales * sales_ratio) AS adjusted_sales
FROM 
    CombinedResults
GROUP BY 
    cd_gender, cd_marital_status
ORDER BY 
    total_demographic_sales DESC;