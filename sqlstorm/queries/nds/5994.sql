
WITH SalesStats AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    ss.d_year,
    ss.d_month_seq,
    ss.total_sales,
    ss.total_orders,
    ss.unique_customers,
    COUNT(DISTINCT cd.cd_demo_sk) AS demographic_count,
    SUM(CASE 
        WHEN cd.cd_gender = 'M' THEN 1 
        ELSE 0 
    END) AS male_count,
    SUM(CASE 
        WHEN cd.cd_marital_status = 'M' THEN 1 
        ELSE 0 
    END) AS married_count
FROM 
    SalesStats ss
LEFT JOIN 
    CustomerDemographics cd ON ss.unique_customers = cd.cd_demo_sk
GROUP BY 
    ss.d_year, ss.d_month_seq, ss.total_sales, ss.total_orders, ss.unique_customers
ORDER BY 
    ss.d_year, ss.d_month_seq;
