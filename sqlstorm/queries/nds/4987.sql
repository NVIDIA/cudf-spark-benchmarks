
WITH SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
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
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
TopCustomers AS (
    SELECT 
        ss.ws_bill_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.ca_city,
        cs.ca_state,
        ROUND(ss.total_sales * 1.1, 2) AS adjusted_sales
    FROM 
        SalesSummary ss
    JOIN 
        CustomerDetails cs ON ss.ws_bill_customer_sk = cs.c_customer_sk
    WHERE 
        ss.sales_rank <= 10
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.ca_city,
    tc.ca_state,
    tc.adjusted_sales
FROM 
    TopCustomers tc
WHERE 
    tc.adjusted_sales IS NOT NULL
ORDER BY 
    tc.adjusted_sales DESC
LIMIT 10;
