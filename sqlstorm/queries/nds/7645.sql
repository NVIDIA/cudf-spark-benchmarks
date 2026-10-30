
WITH CustomerRank AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
TopCustomers AS (
    SELECT 
        cr.c_customer_sk,
        cr.c_first_name,
        cr.c_last_name,
        cr.cd_gender,
        cr.cd_marital_status,
        cr.cd_purchase_estimate
    FROM 
        CustomerRank cr
    WHERE 
        cr.purchase_rank <= 10
),
SalesSummary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
CustomerSales AS (
    SELECT 
        tc.c_customer_sk,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.order_count, 0) AS order_count
    FROM 
        TopCustomers tc
    LEFT JOIN 
        SalesSummary ss ON tc.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.total_sales,
    cs.order_count,
    ca.ca_city,
    ca.ca_state
FROM 
    CustomerSales cs
JOIN 
    customer c ON cs.c_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    cs.total_sales > 1000
ORDER BY 
    cs.total_sales DESC, cs.order_count DESC;
