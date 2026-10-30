
WITH CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt_inc_tax) AS total_returned_amount,
        COUNT(wr_return_quantity) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
StoreSalesData AS (
    SELECT 
        ss_customer_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(ss_ticket_number) AS total_sales_count
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_customer_sk
),
PromotionsData AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        COUNT(DISTINCT ws_order_number) AS promo_order_count,
        SUM(ws_ext_sales_price) AS total_promo_sales
    FROM 
        web_sales 
    WHERE 
        ws_promo_sk IS NOT NULL
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    COALESCE(ca.ca_city, 'Unknown') AS city,
    COALESCE(CD.total_sales, 0) AS total_store_sales,
    COALESCE(CR.total_returned_amount, 0) AS total_web_returns,
    COALESCE(PD.total_promo_sales, 0) AS total_promo_sales
FROM 
    customer c
LEFT JOIN 
    CustomerReturns CR ON c.c_customer_sk = CR.wr_returning_customer_sk
LEFT JOIN 
    StoreSalesData CD ON c.c_customer_sk = CD.ss_customer_sk
LEFT JOIN 
    PromotionsData PD ON c.c_customer_sk = PD.customer_id
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    (CD.total_sales > 1000 OR CR.total_returned_amount > 500 OR PD.total_promo_sales > 300)
ORDER BY 
    c.c_customer_id;
