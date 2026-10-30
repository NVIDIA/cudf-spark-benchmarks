
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(CASE WHEN ws.ws_ext_discount_amt > 0 THEN 1 END) AS discounted_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        c.c_customer_id, d.d_year
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        c.c_customer_id
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FullReport AS (
    SELECT 
        ss.c_customer_id,
        ss.d_year,
        ss.total_sales,
        ss.order_count,
        ss.avg_sales_price,
        ss.max_sales_price,
        ss.min_sales_price,
        ss.total_discount,
        ss.discounted_orders,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status
    FROM 
        SalesSummary ss
    JOIN 
        Demographics d ON ss.c_customer_id = d.c_customer_id
)
SELECT 
    d_year,
    cd_gender,
    COUNT(c_customer_id) AS customer_count,
    SUM(total_sales) AS total_sales,
    AVG(avg_sales_price) AS avg_sales,
    MAX(max_sales_price) AS highest_sale,
    MIN(min_sales_price) AS lowest_sale,
    SUM(total_discount) AS total_discount_given,
    SUM(discounted_orders) AS total_discounted_orders
FROM 
    FullReport
GROUP BY 
    d_year, cd_gender
ORDER BY 
    d_year, cd_gender;
