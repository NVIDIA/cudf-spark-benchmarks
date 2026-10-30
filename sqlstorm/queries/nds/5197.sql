
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_net_paid
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                               AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        c.c_customer_sk, c.c_current_cdemo_sk
),

TopCustomers AS (
    SELECT 
        cds.c_current_cdemo_sk,
        cds.total_sales,
        cds.total_orders,
        cds.avg_net_paid,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        CustomerSales cds
    JOIN 
        customer_demographics cd ON cds.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cds.total_sales > 1000
    ORDER BY 
        total_sales DESC
    LIMIT 50
)

SELECT 
    ca.ca_country,
    COUNT(tc.c_current_cdemo_sk) AS customer_count,
    AVG(tc.total_sales) AS avg_sales_per_customer,
    SUM(tc.total_orders) AS total_orders_per_country
FROM 
    TopCustomers tc
JOIN 
    customer_address ca ON ca.ca_address_sk IN (
        SELECT c.c_current_addr_sk 
        FROM customer c 
        WHERE c.c_customer_sk IN (SELECT tc.c_current_cdemo_sk FROM TopCustomers tc)
    )
GROUP BY 
    ca.ca_country
ORDER BY 
    customer_count DESC;
