WITH SalesData AS (
    SELECT 
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk,
        d.d_year,
        d.d_month_seq
    FROM 
        catalog_sales cs
    JOIN 
        customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2001
        AND d.d_month_seq IN (1, 2, 3)  
),
AggregateSales AS (
    SELECT 
        d_year,
        d_month_seq,
        cd_gender,
        cd_marital_status,
        hd_income_band_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit
    FROM 
        SalesData
    GROUP BY 
        d_year, d_month_seq, cd_gender, cd_marital_status, hd_income_band_sk
)
SELECT 
    a.d_year,
    a.d_month_seq,
    a.cd_gender,
    a.cd_marital_status,
    a.hd_income_band_sk,
    a.total_quantity,
    a.total_sales,
    a.total_profit,
    RANK() OVER (PARTITION BY a.d_year, a.d_month_seq ORDER BY a.total_profit DESC) AS profit_rank
FROM 
    AggregateSales a
ORDER BY 
    a.d_year, a.d_month_seq, profit_rank;