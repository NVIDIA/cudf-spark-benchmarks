
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_ext_tax) AS total_tax,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2458849 AND 2458855  
    GROUP BY 
        ws.ws_sold_date_sk, cd.cd_gender, cd.cd_marital_status, ib.ib_income_band_sk
),
SalesSummary AS (
    SELECT 
        total_quantity,
        total_sales,
        total_discount,
        total_tax,
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT ws_sold_date_sk) AS sales_days
    FROM 
        SalesData
    GROUP BY 
        total_quantity, total_sales, total_discount, total_tax, cd_gender, cd_marital_status
)
SELECT 
    cd_gender,
    cd_marital_status,
    AVG(total_quantity) AS avg_quantity_per_gender,
    AVG(total_sales) AS avg_sales_per_gender,
    SUM(total_discount) AS total_discount_by_genders,
    SUM(total_tax) AS total_tax_by_genders,
    COUNT(*) AS number_of_entries,
    MIN(sales_days) AS min_sales_days,
    MAX(sales_days) AS max_sales_days
FROM 
    SalesSummary
GROUP BY 
    cd_gender, cd_marital_status
ORDER BY 
    cd_gender, cd_marital_status;
