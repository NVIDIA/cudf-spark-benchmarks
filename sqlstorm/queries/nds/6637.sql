
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        d.d_year,
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ib.ib_income_band_sk
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        d.d_year BETWEEN 2022 AND 2023
    GROUP BY 
        ws.ws_order_number, d.d_year, c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating, ib.ib_income_band_sk
)
SELECT 
    d_year,
    cd_gender,
    cd_marital_status,
    COUNT(DISTINCT ws_order_number) AS order_count,
    SUM(total_quantity) AS total_quantity_sold,
    SUM(total_sales) AS total_sales_amount,
    AVG(total_discount) AS avg_discount_amount,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    ib_income_band_sk
FROM 
    SalesData
GROUP BY 
    d_year, cd_gender, cd_marital_status, ib_income_band_sk
ORDER BY 
    d_year, cd_gender, cd_marital_status, unique_customers DESC;
