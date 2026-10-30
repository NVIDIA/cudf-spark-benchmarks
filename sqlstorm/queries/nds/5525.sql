
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_ext_tax) AS total_tax,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        store s ON ws.ws_ship_addr_sk = s.s_store_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d) AND (SELECT MAX(d.d_date_sk) FROM date_dim d)
        AND i.i_current_price > 10.00
    GROUP BY 
        ws.ws_item_sk
),

CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        EXTRACT(YEAR FROM d.d_date) AS year
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE 
        cd.cd_marital_status = 'M'
)

SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT sds.ws_item_sk) AS unique_items_sold,
    SUM(sds.total_quantity) AS total_units_sold,
    SUM(sds.total_sales) AS total_revenue,
    SUM(sds.total_discount) AS total_discount_given,
    SUM(sds.total_tax) AS total_tax_collected,
    cd.year
FROM 
    SalesData sds
JOIN 
    CustomerData cd ON sds.ws_item_sk = cd.c_customer_sk
GROUP BY 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.year
ORDER BY 
    total_revenue DESC,
    unique_items_sold DESC
LIMIT 100;
