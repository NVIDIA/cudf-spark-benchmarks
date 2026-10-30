WITH  MonthlySales AS (
    SELECT 
        d.d_year,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year
    
    UNION ALL

    SELECT 
        d.d_year,
        SUM(cs_ext_sales_price) AS total_sales
    FROM 
        date_dim d
    JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    GROUP BY 
        d.d_year
), 
CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_returns,
        COUNT(DISTINCT wr.wr_order_number) AS web_returns,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0)) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid + cs.cs_net_paid) DESC) AS ranking
    FROM 
        customer c
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    LEFT JOIN 
        catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
)

SELECT 
    cs.c_customer_sk,
    cs.total_spent,
    cs.catalog_returns,
    cs.web_returns,
    cast('2002-10-01' as date) - DATE '2001-01-01' AS days_since_first_purchase,
    ms.total_sales AS yearly_sales
FROM 
    CustomerSummary cs
LEFT JOIN 
    MonthlySales ms ON ms.d_year = EXTRACT(YEAR FROM cast('2002-10-01' as date))
WHERE 
    cs.ranking <= 10 
ORDER BY 
    cs.total_spent DESC;