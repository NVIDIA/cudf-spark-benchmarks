WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450000 AND 2450650  
    GROUP BY 
        ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        rc.ws_bill_customer_sk,
        rc.total_sales,
        rc.order_count,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        ranked_sales rc
    JOIN 
        customer_demographics cd ON rc.ws_bill_customer_sk = cd.cd_demo_sk
    WHERE 
        rc.rank <= 100  
),
sales_by_state AS (
    SELECT 
        ca_state,
        SUM(total_sales) AS state_sales,
        COUNT(ws_bill_customer_sk) AS customer_count
    FROM 
        top_customers tc
    JOIN 
        customer c ON tc.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca_state
),
final_report AS (
    SELECT 
        sbs.ca_state,
        sbs.state_sales,
        sbs.customer_count,
        (state_sales / NULLIF(customer_count, 0)) AS average_sales_per_customer
    FROM 
        sales_by_state sbs
)
SELECT 
    ca_state,
    state_sales,
    customer_count,
    average_sales_per_customer
FROM 
    final_report
ORDER BY 
    state_sales DESC;