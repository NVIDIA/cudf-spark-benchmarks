
WITH EnhancedCustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        CAST(cd.cd_purchase_estimate AS STRING) AS purchase_estimate_str,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married' 
            ELSE 'Single' 
        END AS marital_status_desc,
        CONCAT('Customer: ', c.c_customer_id, ' has an estimated annual purchase of ', cd.cd_purchase_estimate) AS purchase_description
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
TransactionMetrics AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales_amount,
        SUM(ws_ext_discount_amt) AS total_discount,
        SUM(ws_net_profit) AS net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalBenchmark AS (
    SELECT 
        ec.customer_full_name,
        ec.ca_city,
        ec.ca_state,
        ec.cd_gender,
        ec.marital_status_desc,
        tm.total_orders,
        tm.total_sales_amount,
        tm.total_discount,
        tm.net_profit,
        ROW_NUMBER() OVER (ORDER BY tm.net_profit DESC) AS rank
    FROM 
        EnhancedCustomerData ec
    LEFT JOIN 
        TransactionMetrics tm ON ec.c_customer_sk = tm.customer_sk
)
SELECT 
    rank,
    customer_full_name,
    ca_city,
    ca_state,
    cd_gender,
    marital_status_desc,
    total_orders,
    total_sales_amount,
    total_discount,
    net_profit
FROM 
    FinalBenchmark
WHERE 
    total_orders > 0
ORDER BY 
    rank;
