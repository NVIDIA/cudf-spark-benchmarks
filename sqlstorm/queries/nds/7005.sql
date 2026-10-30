
WITH SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        ws.ws_ship_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_ship_date_sk = dd.d_date_sk
    WHERE 
        cd.cd_marital_status = 'M' AND 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_bill_customer_sk, ws.ws_ship_date_sk
),
TopCustomers AS (
    SELECT 
        sd.ws_bill_customer_sk,
        sd.total_sales,
        sd.order_count
    FROM 
        SalesData sd
    WHERE 
        sd.sales_rank <= 10
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    tc.total_sales,
    tc.order_count,
    cd.cd_gender,
    cd.cd_education_status
FROM 
    TopCustomers tc
JOIN 
    customer c ON tc.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
ORDER BY 
    tc.total_sales DESC;
