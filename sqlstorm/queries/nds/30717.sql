
WITH  sales_hierarchy AS (
    SELECT 
        c.c_customer_id,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_gender, 'U') AS gender,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
top_sales AS (
    SELECT * FROM sales_hierarchy
    WHERE rank <= 10
),
sales_returned AS (
    SELECT 
        sr.sr_returned_date_sk,
        SUM(sr.sr_return_amt) AS total_returned,
        COUNT(sr.sr_ticket_number) AS return_count
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_returned_date_sk
),
daily_sales AS (
    SELECT 
        d.d_date_sk,
        d.d_date,
        SUM(ws.ws_ext_sales_price) AS daily_sales,
        SUM(COALESCE(sr.total_returned, 0)) AS total_returns
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        sales_returned sr ON d.d_date_sk = sr.sr_returned_date_sk
    GROUP BY 
        d.d_date_sk, d.d_date
)
SELECT 
    ds.d_date,
    COALESCE(ts.total_sales, 0) AS top_sales,
    ds.daily_sales,
    ds.total_returns,
    (ds.daily_sales - COALESCE(ds.total_returns, 0)) AS net_sales
FROM 
    daily_sales ds
LEFT JOIN 
    top_sales ts ON ts.c_customer_sk = ds.d_date_sk
WHERE 
    ds.daily_sales > (SELECT AVG(ds2.daily_sales) FROM daily_sales ds2)
ORDER BY 
    ds.d_date DESC
LIMIT 20;
