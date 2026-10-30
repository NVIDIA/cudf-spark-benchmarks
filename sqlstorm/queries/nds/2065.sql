
WITH SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        DENSE_RANK() OVER (ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2022-01-01') AND 
                               (SELECT d_date_sk FROM date_dim WHERE d_date = '2022-12-31')
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ss.total_sales,
        ss.total_orders
    FROM 
        customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        LEFT JOIN SalesSummary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
    WHERE
        (cd.cd_marital_status IS NOT NULL AND cd.cd_marital_status IN ('M', 'S')) OR
        (ca.ca_state = 'NY' AND cd.cd_gender = 'F')
)
SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.ca_city,
    cd.ca_state,
    COALESCE(cd.total_sales, 0) AS total_sales,
    COALESCE(cd.total_orders, 0) AS total_orders,
    CASE 
        WHEN cd.total_sales > 10000 THEN 'High Value'
        WHEN cd.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segmentation
FROM 
    CustomerDetails cd
ORDER BY 
    cd.total_sales DESC
LIMIT 100;

