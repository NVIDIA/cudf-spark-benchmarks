WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_paid) AS total_net_paid,
        AVG(ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451000 AND 2451500 
    GROUP BY 
        ws_bill_customer_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        addr.ca_city,
        addr.ca_state,
        addr.ca_country
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address addr ON c.c_current_addr_sk = addr.ca_address_sk
),
ranked_sales AS (
    SELECT 
        ss.ws_bill_customer_sk,
        ss.total_sales,
        ss.total_net_paid,
        ss.avg_discount,
        ss.order_count,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        sales_summary ss
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    rs.total_sales,
    rs.total_net_paid,
    rs.avg_discount,
    rs.order_count,
    rs.sales_rank
FROM 
    ranked_sales rs
JOIN 
    customer_info ci ON rs.ws_bill_customer_sk = ci.c_customer_sk
WHERE 
    (ci.ca_state = 'CA' OR ci.ca_state = 'NY') 
    AND (rs.order_count > 5 OR rs.avg_discount IS NOT NULL)
ORDER BY 
    rs.sales_rank
LIMIT 100;