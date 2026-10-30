
WITH  SalesTrends AS (
    SELECT 
        d.d_year, 
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
    UNION ALL
    SELECT 
        d.d_year, 
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM 
        catalog_sales cs
    JOIN 
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year < (SELECT MAX(d_year) FROM date_dim)
    GROUP BY 
        d.d_year
), 
CustomerReturns AS (
    SELECT 
        c.c_customer_id, 
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(sr.sr_ticket_number) AS total_returns
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id, 
        cr.total_return_amount,
        cr.total_returns,
        ROW_NUMBER() OVER (ORDER BY cr.total_return_amount DESC) AS rnk
    FROM 
        CustomerReturns cr
    JOIN 
        customer c ON cr.c_customer_id = c.c_customer_id
    WHERE 
        cr.total_return_amount IS NOT NULL
)
SELECT 
    st.d_year,
    st.total_net_profit,
    tc.c_customer_id,
    tc.total_return_amount,
    tc.total_returns
FROM 
    SalesTrends st
LEFT JOIN 
    TopCustomers tc ON st.d_year = (SELECT MAX(d_year) FROM date_dim WHERE d_current_year = 'Y')
WHERE 
    (tc.total_returns > 5 OR tc.total_return_amount IS NULL)
ORDER BY 
    st.d_year, tc.total_return_amount DESC;
