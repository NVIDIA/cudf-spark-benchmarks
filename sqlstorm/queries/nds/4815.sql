
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_bill_customer_sk
), CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        sa.ca_city,
        sa.ca_state
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address sa ON c.c_current_addr_sk = sa.ca_address_sk
), RankedSales AS (
    SELECT 
        sd.ws_bill_customer_sk,
        sd.total_sales,
        sd.total_orders,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.ca_city,
    cd.ca_state,
    rs.total_sales,
    rs.total_orders,
    rs.sales_rank
FROM 
    RankedSales rs
JOIN 
    CustomerDetails cd ON rs.ws_bill_customer_sk = cd.c_customer_sk
WHERE 
    cd.cd_marital_status = 'M'
    AND cd.cd_purchase_estimate > 1000
    AND cd.cd_credit_rating IS NOT NULL
    AND rs.total_orders > 5
ORDER BY 
    rs.total_sales DESC
LIMIT 10;
