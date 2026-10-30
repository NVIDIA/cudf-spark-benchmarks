
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr_net_loss) AS total_net_loss
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),

StoreSales AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(ss_ticket_number) AS total_tickets,
        AVG(ss_net_paid) AS avg_sale_value
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (
            SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023
        ) AND (
            SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023
        )
    GROUP BY 
        ss_store_sk
),

HighReturnCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.total_returns,
        cr.total_return_amount,
        cr.total_net_loss,
        ss.total_sales,
        ss.total_tickets,
        ss.avg_sale_value
    FROM 
        customer c
    JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        StoreSales ss ON ss.ss_store_sk = c.c_current_addr_sk
    WHERE 
        cr.total_returns > 5 AND 
        cr.total_net_loss > 100
)

SELECT 
    hrc.c_customer_sk,
    hrc.c_first_name,
    hrc.c_last_name,
    hrc.total_returns,
    hrc.total_return_amount,
    hrc.total_net_loss,
    COALESCE(hrc.total_sales, 0) AS total_sales,
    COALESCE(hrc.total_tickets, 0) AS total_tickets,
    COALESCE(hrc.avg_sale_value, 0) AS avg_sale_value,
    (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_returning_customer_sk = hrc.c_customer_sk) AS web_returns_count
FROM 
    HighReturnCustomers hrc
ORDER BY 
    hrc.total_net_loss DESC;
