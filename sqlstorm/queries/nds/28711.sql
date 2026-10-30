
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
DateSummary AS (
    SELECT 
        d.d_date_id,
        d.d_year,
        d.d_month_seq,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date_id, d.d_year, d.d_month_seq
),
FilteredCustomers AS (
    SELECT 
        cd.*,
        ds.total_orders,
        ds.total_sales
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        DateSummary ds ON cd.c_customer_id = ds.d_date_id
    WHERE 
        (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
        AND cd.cd_purchase_estimate > 1000
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    total_orders,
    total_sales,
    CASE 
        WHEN total_sales > 5000 THEN 'High Value'
        WHEN total_sales BETWEEN 2000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    FilteredCustomers
ORDER BY 
    total_sales DESC
LIMIT 100;
