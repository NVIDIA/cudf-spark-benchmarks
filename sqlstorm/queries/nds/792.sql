
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk AS customer,
        c.total_sales,
        RANK() OVER (ORDER BY c.total_sales DESC) AS sales_rank
    FROM CustomerSales c
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cs.total_sales) AS demographic_sales
    FROM TopCustomers tc
    JOIN customer_demographics cd ON tc.customer = cd.cd_demo_sk
    JOIN CustomerSales cs ON tc.customer = cs.c_customer_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(cd.cd_demo_sk) AS demographic_count,
    SUM(cd.demographic_sales) AS total_demographic_sales,
    ROUND(AVG(cd.demographic_sales), 2) AS average_sales_per_demographic
FROM CustomerDemographics cd
GROUP BY cd.cd_gender, cd.cd_marital_status
HAVING SUM(cd.demographic_sales) > (SELECT AVG(demographic_sales) FROM CustomerDemographics)
ORDER BY total_demographic_sales DESC
