
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        a.ca_city,
        a.ca_state,
        a.ca_country,
        d.d_year,
        d.d_month_seq,
        d.d_day_name
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        date_dim AS d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND cd.cd_purchase_estimate > 1000
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk, 
        SUM(ws.ws_ext_sales_price) AS total_sales, 
        COUNT(ws.ws_order_number) AS total_orders, 
        SUM(ws.ws_ext_discount_amt) AS total_discounts
    FROM 
        web_sales AS ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        c.ca_city,
        c.ca_state,
        c.ca_country,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(s.total_orders, 0) AS total_orders,
        COALESCE(s.total_discounts, 0) AS total_discounts
    FROM 
        CustomerData AS c
    LEFT JOIN 
        SalesData AS s ON c.c_customer_sk = s.ws_bill_customer_sk
)
SELECT 
    ca_city, 
    ca_state, 
    COUNT(*) AS customer_count, 
    SUM(total_sales) AS total_sales_amount, 
    AVG(total_orders) AS average_orders_per_customer, 
    SUM(total_discounts) AS total_discount_given
FROM 
    CombinedData
GROUP BY 
    ca_city, 
    ca_state
HAVING 
    COUNT(*) > 5
ORDER BY 
    total_sales_amount DESC
LIMIT 10;
