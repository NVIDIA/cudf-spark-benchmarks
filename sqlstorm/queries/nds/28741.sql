
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        cd.c_customer_sk,
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.ca_city,
        cd.ca_state,
        ss.total_quantity,
        ss.total_sales,
        ss.total_orders
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesSummary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    cb.*,
    CASE 
        WHEN cb.total_sales IS NULL THEN 'No Sales'
        WHEN cb.total_sales < 100 THEN 'Low Spender'
        WHEN cb.total_sales BETWEEN 100 AND 500 THEN 'Mid Spender'
        ELSE 'High Spender'
    END AS customer_spending_category
FROM 
    CombinedData cb
ORDER BY 
    cb.total_sales DESC;
