
WITH sales_summary AS (
    SELECT 
        customer.c_customer_id,
        COUNT(DISTINCT web_sales.ws_order_number) AS total_orders,
        SUM(web_sales.ws_ext_sales_price) AS total_sales,
        AVG(web_sales.ws_net_paid) AS avg_order_value,
        COUNT(DISTINCT web_sales.ws_item_sk) AS unique_items_sold
    FROM 
        web_sales
    JOIN 
        customer ON web_sales.ws_bill_customer_sk = customer.c_customer_sk
    JOIN 
        customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    WHERE 
        customer_demographics.cd_gender = 'F' 
        AND customer_demographics.cd_marital_status = 'M' 
        AND customer_demographics.cd_education_status IN ('PhD', 'Master') 
    GROUP BY 
        customer.c_customer_id
),
top_customers AS (
    SELECT 
        c_customer_id,
        total_orders,
        total_sales,
        avg_order_value,
        unique_items_sold,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    t.c_customer_id,
    t.total_orders,
    t.total_sales,
    t.avg_order_value,
    t.unique_items_sold,
    customer_address.ca_city,
    customer_address.ca_state
FROM 
    top_customers t
JOIN 
    customer ON t.c_customer_id = customer.c_customer_id
JOIN 
    customer_address ON customer.c_current_addr_sk = customer_address.ca_address_sk
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.total_sales DESC;
