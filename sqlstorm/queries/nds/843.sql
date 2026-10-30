
WITH SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2022 AND d_month_seq BETWEEN 1 AND 6
        )
    GROUP BY 
        ws_bill_customer_sk
),
CustomerAnalysis AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.total_orders, 0) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY COALESCE(ss.total_sales, 0) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        SalesSummary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(ca.ca_gmt_offset) AS total_gmt_offset,
    COUNT(DISTINCT ca.ca_address_id) AS unique_addresses,
    AVG(cust.total_sales) AS avg_sales_per_customer,
    COUNT(CASE WHEN cust.sales_rank <= 10 THEN 1 END) AS top_sales_customers
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    CustomerAnalysis cust ON c.c_customer_sk = cust.c_customer_sk
WHERE 
    (cust.total_sales > 500 OR (cust.total_sales = 0 AND cust.cd_marital_status = 'S'))
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 5
ORDER BY 
    avg_sales_per_customer DESC;
