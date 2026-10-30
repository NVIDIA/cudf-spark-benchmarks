
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_paid_inc_tax) AS average_order_value
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
),
Demographics AS (
    SELECT 
        c.c_customer_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        sd.order_count,
        sd.average_order_value,
        sd.total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_customer_sk = cd.cd_demo_sk
    JOIN 
        SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'M' AND 
        cd.cd_marital_status = 'S' AND 
        cd.cd_education_status LIKE '%Graduate%'
),
TopCustomers AS (
    SELECT 
        d.cd_gender, d.cd_marital_status, 
        COUNT(d.c_customer_sk) AS customer_count,
        SUM(d.total_profit) AS total_profit_sum,
        AVG(d.average_order_value) AS avg_order_value
    FROM 
        Demographics d
    GROUP BY 
        d.cd_gender, d.cd_marital_status
)
SELECT 
    tc.cd_gender, 
    tc.cd_marital_status, 
    tc.customer_count, 
    tc.total_profit_sum, 
    tc.avg_order_value, 
    ROW_NUMBER() OVER (ORDER BY tc.total_profit_sum DESC) AS rank
FROM 
    TopCustomers tc
WHERE 
    tc.customer_count > 5
ORDER BY 
    tc.total_profit_sum DESC;
