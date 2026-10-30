
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_dep_count,
        cd_income_band.ib_lower_bound,
        cd_income_band.ib_upper_bound,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        income_band cd_income_band ON hd.hd_income_band_sk = cd_income_band.ib_income_band_sk
),
DateSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month
    FROM 
        web_sales 
    JOIN 
        date_dim d ON ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws_bill_customer_sk, d.d_year, d.d_month_seq
),
CustomerSales AS (
    SELECT 
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        cd.ca_zip,
        ds.total_sales,
        ds.order_count,
        ds.sales_year,
        ds.sales_month
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        DateSales ds ON cd.c_customer_sk = ds.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    ca_zip,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(order_count, 0) AS order_count,
    sales_year,
    sales_month
FROM 
    CustomerSales
ORDER BY 
    sales_year DESC, sales_month DESC, total_sales DESC
LIMIT 100;
