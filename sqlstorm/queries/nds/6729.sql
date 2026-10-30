
WITH sales_data AS (
    SELECT 
        ws.ws_web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        w.w_warehouse_id,
        d.d_year,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
),
aggregated_sales AS (
    SELECT 
        sd.ws_web_site_sk,
        sd.w_warehouse_id,
        sd.d_year,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_sales,
        COUNT(sd.ws_order_number) AS total_orders,
        COUNT(DISTINCT sd.c_customer_id) AS unique_customers,
        COUNT(CASE WHEN sd.cd_gender = 'M' THEN 1 END) AS male_customers,
        COUNT(CASE WHEN sd.cd_gender = 'F' THEN 1 END) AS female_customers,
        COUNT(CASE WHEN sd.cd_marital_status = 'M' THEN 1 END) AS married_customers,
        COUNT(CASE WHEN sd.cd_marital_status = 'S' THEN 1 END) AS single_customers
    FROM 
        sales_data sd
    GROUP BY 
        sd.ws_web_site_sk, sd.w_warehouse_id, sd.d_year
)
SELECT 
    ag.ws_web_site_sk,
    ag.w_warehouse_id,
    ag.d_year,
    ag.total_sales,
    ag.total_orders,
    ag.unique_customers,
    ag.male_customers,
    ag.female_customers,
    ag.married_customers,
    ag.single_customers,
    RANK() OVER (PARTITION BY ag.d_year ORDER BY ag.total_sales DESC) AS sales_rank
FROM 
    aggregated_sales ag
ORDER BY 
    ag.d_year, ag.total_sales DESC;
