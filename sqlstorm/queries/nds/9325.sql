
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_net_paid) AS average_order_value,
        MIN(ws_ship_date_sk) AS first_sale_date,
        MAX(ws_ship_date_sk) AS last_sale_date,
        DENSE_RANK() OVER (ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
                            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_bill_customer_sk
), customer_details AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ss.total_sales,
        ss.order_count,
        ss.average_order_value,
        ss.first_sale_date,
        ss.last_sale_date,
        ss.sales_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        sales_summary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    customer_name,
    total_sales,
    order_count,
    average_order_value,
    first_sale_date,
    last_sale_date,
    sales_rank,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ca_city,
    ca_state,
    ca_country
FROM 
    customer_details
WHERE 
    sales_rank <= 10
ORDER BY 
    total_sales DESC;
