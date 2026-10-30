
WITH CustomerData AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        d.d_year,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2018 AND 2022
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status,
        cd.cd_education_status, cd.cd_purchase_estimate, d.d_year
), AvgSpend AS (
    SELECT 
        d_year,
        AVG(total_spent) AS avg_spent
    FROM
        CustomerData
    GROUP BY 
        d_year
), OrderCount AS (
    SELECT
        d_year,
        SUM(total_orders) AS total_orders
    FROM
        CustomerData
    GROUP BY
        d_year
)
SELECT 
    a.d_year,
    a.avg_spent,
    o.total_orders
FROM 
    AvgSpend a
JOIN 
    OrderCount o ON a.d_year = o.d_year
ORDER BY 
    a.d_year;
