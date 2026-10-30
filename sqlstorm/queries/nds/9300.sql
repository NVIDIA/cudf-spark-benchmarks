
WITH daily_sales AS (
    SELECT 
        d.d_date AS sales_date,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_units_sold
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        d.d_date
),
customer_summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
sales_by_region AS (
    SELECT 
        ca.ca_state,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_state
),
combined_report AS (
    SELECT 
        ds.sales_date,
        ds.total_sales,
        ds.total_orders,
        ds.total_units_sold,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.total_customers,
        cs.avg_purchase_estimate,
        sr.ca_state,
        sr.total_sales AS region_sales
    FROM 
        daily_sales ds
    CROSS JOIN 
        customer_summary cs
    CROSS JOIN 
        sales_by_region sr
)
SELECT 
    sales_date,
    total_sales,
    total_orders,
    total_units_sold,
    cd_gender,
    cd_marital_status,
    total_customers,
    avg_purchase_estimate,
    ca_state,
    region_sales
FROM 
    combined_report
ORDER BY 
    sales_date, cd_gender, ca_state;
