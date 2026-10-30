
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS number_of_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk 
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
customer_purchases AS (
    SELECT 
        c.c_customer_sk,
        SUM(sd.total_sales) AS customer_total_spent,
        COUNT(DISTINCT sd.ws_item_sk) AS unique_items_purchased
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        sales_data sd ON ws.ws_item_sk = sd.ws_item_sk
    GROUP BY 
        c.c_customer_sk
),
high_value_customers AS (
    SELECT 
        cp.c_customer_sk,
        cp.customer_total_spent,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        customer_purchases cp
    JOIN 
        customer_demographics cd ON cp.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cp.customer_total_spent > (SELECT AVG(customer_total_spent) FROM customer_purchases)
)
SELECT 
    hvc.c_customer_sk,
    hvc.customer_total_spent,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_credit_rating,
    ca.ca_city,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders
FROM 
    high_value_customers hvc
JOIN 
    customer c ON hvc.c_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = hvc.c_customer_sk
GROUP BY 
    hvc.c_customer_sk, 
    hvc.customer_total_spent, 
    hvc.cd_gender, 
    hvc.cd_marital_status, 
    hvc.cd_credit_rating, 
    ca.ca_city
ORDER BY 
    hvc.customer_total_spent DESC
LIMIT 50;
