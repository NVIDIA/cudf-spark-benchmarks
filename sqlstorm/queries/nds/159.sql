
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),

ReturnDetails AS (
    SELECT 
        wr.wr_returning_customer_sk,
        COUNT(DISTINCT wr.wr_order_number) AS total_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_returns_value
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returning_customer_sk
),

CombinedDetails AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_quantity_sold,
        cs.total_spent,
        COALESCE(rd.total_returns, 0) AS total_returns,
        COALESCE(rd.total_returns_value, 0) AS total_returns_value
    FROM 
        CustomerSales cs
    LEFT JOIN 
        ReturnDetails rd ON cs.c_customer_sk = rd.wr_returning_customer_sk
),

RankedCustomers AS (
    SELECT 
        cd.*,
        RANK() OVER (ORDER BY total_spent DESC) AS rank_by_spending,
        RANK() OVER (ORDER BY total_returns_value DESC) AS rank_by_returns_value
    FROM 
        CombinedDetails cd
)

SELECT 
    rc.c_customer_sk,
    rc.c_first_name,
    rc.c_last_name,
    rc.total_quantity_sold,
    rc.total_spent,
    rc.total_returns,
    rc.total_returns_value,
    rc.rank_by_spending,
    rc.rank_by_returns_value
FROM 
    RankedCustomers rc
WHERE 
    rc.rank_by_spending <= 10 OR rc.rank_by_returns_value <= 10
ORDER BY 
    rc.rank_by_spending, rc.rank_by_returns_value;
