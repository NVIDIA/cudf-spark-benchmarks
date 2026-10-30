WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        ws_sold_date_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= 2458510 
    GROUP BY 
        ws_bill_customer_sk, ws_sold_date_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_country
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
TopCustomers AS (
    SELECT 
        sd.ws_bill_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        sd.total_sales,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY sd.total_sales DESC) as sales_rank
    FROM 
        SalesData sd
    JOIN 
        CustomerDemographics cd ON sd.ws_bill_customer_sk = cd.c_customer_sk
)
SELECT 
    tc.ws_bill_customer_sk,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_sales,
    (SELECT AVG(total_sales) FROM SalesData WHERE ws_bill_customer_sk = tc.ws_bill_customer_sk) AS avg_sales,
    CASE 
        WHEN tc.sales_rank <= 5 THEN 'Top Performer'
        ELSE 'Regular Performer'
    END AS performance_category
FROM 
    TopCustomers tc
WHERE 
    tc.total_sales > (SELECT AVG(total_sales) FROM SalesData) 
ORDER BY 
    tc.total_sales DESC;