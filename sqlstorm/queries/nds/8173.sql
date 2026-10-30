
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status 
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 

SalesData AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_sales_price) AS total_sales 
    FROM 
        web_sales ws 
    GROUP BY 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk
), 

DailySales AS (
    SELECT 
        dd.d_date_sk,
        dd.d_date,
        SUM(sd.total_quantity) AS daily_total_quantity,
        SUM(sd.total_sales) AS daily_total_sales 
    FROM 
        date_dim dd
    JOIN 
        SalesData sd ON dd.d_date_sk = sd.ws_sold_date_sk 
    GROUP BY 
        dd.d_date_sk, 
        dd.d_date
), 

TopCustomers AS (
    SELECT 
        cd.c_customer_sk, 
        cd.c_first_name, 
        cd.c_last_name, 
        SUM(ds.daily_total_sales) AS total_spent 
    FROM 
        CustomerDetails cd 
    JOIN 
        web_sales ws ON cd.c_customer_sk = ws.ws_bill_customer_sk 
    JOIN 
        DailySales ds ON ws.ws_sold_date_sk = ds.d_date_sk 
    GROUP BY 
        cd.c_customer_sk, 
        cd.c_first_name, 
        cd.c_last_name 
    ORDER BY 
        total_spent DESC 
    LIMIT 10
)

SELECT 
    tc.c_customer_sk, 
    tc.c_first_name, 
    tc.c_last_name, 
    tc.total_spent, 
    ds.daily_total_quantity, 
    ds.daily_total_sales 
FROM 
    TopCustomers tc 
JOIN 
    DailySales ds ON tc.c_customer_sk = ds.d_date_sk 
ORDER BY 
    tc.total_spent DESC, 
    ds.daily_total_sales DESC;
