
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_sk
), DemographicDetails AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_country,
        ca.ca_state
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), SalesSummary AS (
    SELECT 
        dd.d_year,
        dd.d_month_seq,
        SUM(cs.total_sales) AS total_sales,
        COUNT(cs.c_customer_sk) AS customer_count
    FROM 
        date_dim dd
    JOIN 
        CustomerSales cs ON dd.d_date_sk = cs.c_customer_sk
    GROUP BY 
        dd.d_year, dd.d_month_seq
)
SELECT 
    ds.d_year,
    ds.d_month_seq,
    ds.total_sales,
    ds.customer_count,
    COUNT(DISTINCT dd.cd_demo_sk) AS demographic_count
FROM 
    SalesSummary ds
JOIN 
    DemographicDetails dd ON ds.customer_count > 0
GROUP BY 
    ds.d_year, ds.d_month_seq, ds.total_sales, ds.customer_count
ORDER BY 
    ds.d_year DESC, ds.d_month_seq DESC
LIMIT 1000;
