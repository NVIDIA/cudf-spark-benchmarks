
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
TopCustomers AS (
    SELECT 
        c.c_customer_sk AS customer_sk, 
        c.c_first_name AS first_name, 
        c.c_last_name AS last_name, 
        c.total_spent, 
        c.order_count,
        RANK() OVER (ORDER BY c.total_spent DESC) AS rank 
    FROM 
        CustomerSales c
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_purchase_estimate > 5000
)
SELECT 
    tc.first_name,
    tc.last_name,
    tc.total_spent,
    tc.order_count,
    cd.cd_gender,
    cd.cd_marital_status,
    CASE 
        WHEN cd.cd_credit_rating IS NULL THEN 'Not Rated'
        ELSE cd.cd_credit_rating 
    END AS credit_rating_status,
    COALESCE(SUM(cl.cr_return_amount), 0) AS total_returns
FROM 
    TopCustomers tc
JOIN 
    CustomerDemographics cd ON tc.customer_sk = cd.cd_demo_sk
LEFT JOIN 
    catalog_returns cl ON tc.customer_sk = cl.cr_returning_customer_sk
WHERE 
    tc.rank <= 10
GROUP BY 
    tc.first_name, 
    tc.last_name, 
    tc.total_spent, 
    tc.order_count, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_credit_rating
ORDER BY 
    tc.total_spent DESC;
