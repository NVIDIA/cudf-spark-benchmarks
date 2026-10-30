
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
    HAVING 
        COUNT(DISTINCT sr_ticket_number) > 3
),
HighValueItems AS (
    SELECT 
        i_item_sk,
        SUM(ws_ext_sales_price) AS total_sales_value
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        i_item_sk
    HAVING 
        SUM(ws_ext_sales_price) > 1000
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
    HAVING 
        COUNT(DISTINCT sr_ticket_number) > 1 AND SUM(sr_return_amt_inc_tax) IS NOT NULL
),
SalesOverTime AS (
    SELECT 
        d.d_date,
        SUM(ws_ext_sales_price) AS daily_sales,
        COUNT(ws_order_number) AS total_orders,
        RANK() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        d.d_date
)
SELECT 
    tc.c_customer_id,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.return_count,
    tc.total_return_amt,
    sot.d_date,
    sot.daily_sales,
    sot.total_orders
FROM 
    TopCustomers tc
JOIN 
    SalesOverTime sot ON tc.return_count > 0 
WHERE 
    sot.sales_rank <= 5 
ORDER BY 
    tc.total_return_amt DESC, sot.daily_sales DESC
LIMIT 10 OFFSET 0;
