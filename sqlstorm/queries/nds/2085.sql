
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 2450032 AND 2450397 
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales
    FROM
        CustomerSales cs
    JOIN
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE
        cd.cd_credit_rating = 'Good' AND cs.total_web_sales > 1000
),
SalesSummary AS (
    SELECT
        cwc.c_customer_sk,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        COALESCE(AVG(ws.ws_net_paid_inc_tax), 0) AS avg_order_value
    FROM
        HighValueCustomers cwc
    LEFT JOIN
        web_sales ws ON cwc.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        cwc.c_customer_sk
)
SELECT
    hvc.c_first_name,
    hvc.c_last_name,
    COALESCE(ss.total_profit, 0) AS total_profit,
    COALESCE(ss.avg_order_value, 0) AS avg_order_value,
    (SELECT COUNT(DISTINCT sr.sr_ticket_number) 
     FROM store_returns sr 
     WHERE sr.sr_customer_sk = hvc.c_customer_sk) AS return_count,
    CASE 
        WHEN EXISTS (SELECT 1 FROM store s WHERE s.s_store_sk = hvc.c_customer_sk) THEN 'Regular'
        ELSE 'Occasional'
    END AS customer_type
FROM
    HighValueCustomers hvc
LEFT JOIN
    SalesSummary ss ON hvc.c_customer_sk = ss.c_customer_sk
ORDER BY
    total_profit DESC
LIMIT 10;
