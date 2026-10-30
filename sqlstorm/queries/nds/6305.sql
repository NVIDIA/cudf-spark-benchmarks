
WITH CustomerSpend AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_spend,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_ext_sales_price) AS avg_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20000101 AND 20221231
    GROUP BY 
        c.c_customer_sk
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cs.total_spend,
        cs.order_count,
        cs.avg_order_value
    FROM 
        customer_demographics cd
    JOIN 
        CustomerSpend cs ON cd.cd_demo_sk = cs.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        d.cd_demo_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.total_spend,
        d.order_count,
        d.avg_order_value
    FROM 
        Demographics d
    WHERE 
        d.total_spend > (SELECT AVG(total_spend) FROM CustomerSpend)
)
SELECT 
    d.cd_gender,
    d.cd_marital_status,
    AVG(d.total_spend) AS avg_spend,
    COUNT(*) AS customer_count,
    COUNT(DISTINCT d.cd_demo_sk) AS unique_customers
FROM 
    HighValueCustomers d
GROUP BY 
    d.cd_gender, d.cd_marital_status
ORDER BY 
    avg_spend DESC;
