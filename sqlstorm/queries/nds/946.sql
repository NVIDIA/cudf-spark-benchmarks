WITH SalesData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= 2450000 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sd.total_sales,
        sd.order_count
    FROM 
        SalesData sd
    JOIN 
        customer c ON sd.c_customer_sk = c.c_customer_sk
    WHERE 
        sd.sales_rank <= 10
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(distinct tc.c_customer_sk) AS customer_count,
        AVG(tc.total_sales) AS average_sales
    FROM 
        customer_demographics cd
    LEFT JOIN 
        TopCustomers tc ON cd.cd_demo_sk = tc.c_customer_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count,
    cd.average_sales,
    COALESCE(cd.customer_count, 0) * 100.0 / NULLIF(SUM(cd.customer_count) OVER (), 0) AS percentage_of_total
FROM 
    CustomerDemographics cd
ORDER BY 
    cd.cd_gender, cd.cd_marital_status;