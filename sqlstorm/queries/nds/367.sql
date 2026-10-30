
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_return_time_sk,
        sr_item_sk,
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_tax) AS total_return_tax
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk, 
        sr_return_time_sk, 
        sr_item_sk, 
        sr_customer_sk
), 
SalesSummary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_sales_price) AS total_sales_amount,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= 20200101 
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
), 
JoinedData AS (
    SELECT 
        cs.sr_customer_sk AS customer_sk,
        SUM(cs.total_returns) AS total_num_returns,
        ss.total_sales,
        ss.total_sales_amount,
        ss.avg_sales_price
    FROM 
        CustomerReturns cs
    LEFT JOIN 
        SalesSummary ss ON cs.sr_item_sk = ss.ws_item_sk
    GROUP BY 
        cs.sr_customer_sk, ss.total_sales, ss.total_sales_amount, ss.avg_sales_price
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(jd.total_num_returns, 0) AS num_returns,
    COALESCE(jd.total_sales, 0) AS total_sales,
    COALESCE(jd.total_sales_amount, 0) AS total_sales_amount,
    ROUND(COALESCE(jd.avg_sales_price, 0), 2) AS avg_sales_price,
    CASE 
        WHEN COALESCE(jd.total_sales, 0) > 100 THEN 'High Value Customer'
        WHEN COALESCE(jd.total_sales, 0) BETWEEN 50 AND 100 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_segment
FROM 
    customer c
LEFT JOIN 
    JoinedData jd ON c.c_customer_sk = jd.customer_sk
ORDER BY 
    num_returns DESC, 
    total_sales_amount DESC;
