
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        ws.ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND ws.ws_sold_date_sk <= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
),
TopCustomers AS (
    SELECT
        c.*,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        CustomerSales c
)
SELECT 
    t.c_first_name,
    t.c_last_name,
    t.total_sales,
    t.order_count,
    t.cd_gender,
    t.cd_marital_status,
    t.cd_education_status
FROM 
    TopCustomers t
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.total_sales DESC;
