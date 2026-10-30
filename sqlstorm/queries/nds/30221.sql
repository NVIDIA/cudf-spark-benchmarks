
WITH  SalesHistory AS (
    SELECT 
        ss_customer_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions,
        RANK() OVER (PARTITION BY ss_customer_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        ss_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state IS NOT NULL
),
TopCustomers AS (
    SELECT 
        si.ss_customer_sk,
        si.total_sales,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.ca_city,
        ci.ca_state
    FROM 
        SalesHistory si
        JOIN CustomerInfo ci ON si.ss_customer_sk = ci.c_customer_sk
    WHERE 
        si.sales_rank <= 10
),
ReturnsData AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.ca_city,
    tc.ca_state,
    tc.total_sales,
    COALESCE(rd.total_return_amount, 0) AS total_return_amount,
    COALESCE(rd.total_return_quantity, 0) AS total_return_quantity,
    CASE 
        WHEN rd.total_return_quantity IS NULL THEN 'No Returns'
        ELSE 'Has Returns'
    END AS return_status
FROM 
    TopCustomers tc
LEFT JOIN 
    ReturnsData rd ON tc.ss_customer_sk = rd.sr_customer_sk
WHERE 
    tc.total_sales > 500
ORDER BY 
    tc.total_sales DESC;
