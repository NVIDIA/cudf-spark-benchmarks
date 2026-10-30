
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 2000
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
IncomeBandSales AS (
    SELECT 
        h.hd_income_band_sk,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count
    FROM 
        household_demographics h
    JOIN 
        catalog_sales cs ON h.hd_demo_sk = cs.cs_bill_cdemo_sk
    WHERE 
        h.hd_buy_potential = 'High'
    GROUP BY 
        h.hd_income_band_sk
),
DatedSales AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year BETWEEN 2018 AND 2023
    GROUP BY 
        d.d_year
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales,
    cs.order_count,
    ib.total_catalog_sales,
    ib.catalog_order_count,
    ds.total_profit
FROM 
    CustomerSales cs
LEFT JOIN 
    IncomeBandSales ib ON cs.c_customer_sk = ib.hd_income_band_sk
LEFT JOIN 
    DatedSales ds ON ds.total_profit IS NOT NULL
ORDER BY 
    cs.total_sales DESC, cs.order_count DESC;
