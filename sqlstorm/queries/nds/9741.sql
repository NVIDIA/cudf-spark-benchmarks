
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        dd.d_year,
        dd.d_month_seq,
        dd.d_week_seq
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk, dd.d_year, dd.d_month_seq, dd.d_week_seq
), 
CustomerData AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(sd.total_quantity) AS total_quantity,
        SUM(sd.total_sales) AS total_sales,
        SUM(sd.total_discount) AS total_discount
    FROM 
        SalesData sd
    JOIN 
        customer c ON sd.ws_item_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(*) AS customer_count,
    SUM(cd.total_quantity) AS grand_total_quantity,
    SUM(cd.total_sales) AS grand_total_sales,
    SUM(cd.total_discount) AS grand_total_discount,
    AVG(cd.total_sales) AS avg_sales_per_customer,
    MAX(cd.total_sales) AS max_sales_per_customer,
    MIN(cd.total_sales) AS min_sales_per_customer
FROM 
    CustomerData cd
GROUP BY 
    cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
ORDER BY 
    grand_total_sales DESC
LIMIT 10;
