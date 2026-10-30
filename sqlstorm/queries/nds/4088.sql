
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
BestCustomers AS (
    SELECT 
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        r.cd_gender
    FROM 
        RankedCustomers r
    WHERE 
        r.rank <= 5
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerSales AS (
    SELECT 
        b.c_customer_sk,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.order_count, 0) AS order_count
    FROM 
        BestCustomers b
    LEFT JOIN 
        SalesSummary ss ON b.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.total_sales,
    cs.order_count,
    CASE 
        WHEN cs.total_sales > 1000 THEN 'High Value'
        WHEN cs.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    ci.c_first_name || ' ' || ci.c_last_name AS customer_name,
    da.ca_city
FROM 
    CustomerSales cs
JOIN 
    customer ci ON cs.c_customer_sk = ci.c_customer_sk
JOIN 
    customer_address da ON ci.c_current_addr_sk = da.ca_address_sk
WHERE 
    da.ca_state = 'CA'
ORDER BY 
    cs.total_sales DESC
LIMIT 10;
