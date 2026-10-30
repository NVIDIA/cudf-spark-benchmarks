
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
BestCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cr.total_returned_amt,
        cr.return_count,
        RANK() OVER (ORDER BY cr.total_returned_amt DESC) AS rank
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        CustomerReturns AS cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE 
        cd.cd_purchase_estimate > 500
),
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(*) AS order_count,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2400 AND 2600
    GROUP BY 
        ws_bill_customer_sk
),
TopSalesCustomers AS (
    SELECT 
        b.c_customer_sk,
        b.c_first_name,
        b.c_last_name,
        s.order_count,
        s.total_net_profit,
        RANK() OVER (ORDER BY s.total_net_profit DESC) AS sales_rank
    FROM 
        BestCustomers AS b
    JOIN 
        SalesDetails AS s ON b.c_customer_sk = s.ws_bill_customer_sk
    WHERE 
        b.rank <= 100
)
SELECT 
    t.c_customer_sk,
    t.c_first_name,
    t.c_last_name,
    COALESCE(t.order_count, 0) AS total_orders,
    COALESCE(t.total_net_profit, 0) AS total_net_profit,
    COALESCE(cr.total_returned_amt, 0) AS total_returned_amt,
    t.sales_rank
FROM 
    TopSalesCustomers AS t
LEFT JOIN 
    CustomerReturns AS cr ON t.c_customer_sk = cr.sr_customer_sk
ORDER BY 
    t.sales_rank ASC,
    t.total_net_profit DESC;
