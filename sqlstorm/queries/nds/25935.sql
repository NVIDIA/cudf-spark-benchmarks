
WITH enriched_customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS CD_NAME_FULL
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
monthly_sales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year,
        d.d_month_seq
),
city_sales AS (
    SELECT 
        ca.ca_city,
        SUM(ws.ws_ext_sales_price) AS city_sales
    FROM 
        web_sales ws
    JOIN 
        customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_city
),
sales_summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.CD_NAME_FULL,
        cs.ca_city,
        cs.ca_state,
        COALESCE(ms.total_sales, 0) AS monthly_sales,
        COALESCE(ms.total_orders, 0) AS total_orders,
        COALESCE(city.city_sales, 0) AS total_city_sales
    FROM 
        enriched_customer_data cs
    LEFT JOIN 
        monthly_sales ms ON ms.d_year = EXTRACT(YEAR FROM DATE '2002-10-01') AND ms.d_month_seq = EXTRACT(MONTH FROM DATE '2002-10-01')
    LEFT JOIN 
        city_sales city ON city.ca_city = cs.ca_city
)
SELECT 
    s.CD_NAME_FULL,
    s.ca_city,
    s.ca_state,
    s.monthly_sales,
    s.total_orders,
    s.total_city_sales,
    CONCAT('Customer: ', s.CD_NAME_FULL, ', Monthly Sales: ', s.monthly_sales, ', Total City Sales: ', s.total_city_sales) AS report_summary
FROM 
    sales_summary s
WHERE 
    s.monthly_sales > 0
ORDER BY 
    s.total_city_sales DESC;
