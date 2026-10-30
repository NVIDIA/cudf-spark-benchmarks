
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_sales_price, 
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) as PriceRank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2446 AND 2452
),
CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_amount) AS total_returns,
        COUNT(cr_order_number) AS return_count
    FROM 
        catalog_returns
    WHERE 
        cr_returned_date_sk > 2450
    GROUP BY 
        cr_returning_customer_sk
),
StoreSalesSummary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS total_sales,
        AVG(ss_sales_price) AS avg_sales_price,
        COUNT(ss_ticket_number) AS sales_count
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 2450 AND 2452
    GROUP BY 
        ss_store_sk
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(ss.total_sales) AS total_store_sales,
    COALESCE(CR.total_returns, 0) AS total_returns,
    SUM(RS.ws_sales_price * RS.ws_quantity) AS total_web_sales,
    AVG(AVG_WS.avg_sales_price) AS avg_web_sales_price
FROM 
    customer AS c
LEFT JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    StoreSalesSummary AS ss ON c.c_customer_sk = ss.ss_store_sk
LEFT JOIN 
    CustomerReturns AS CR ON c.c_customer_sk = CR.cr_returning_customer_sk
LEFT JOIN 
    RankedSales AS RS ON c.c_customer_sk = RS.ws_item_sk
LEFT JOIN (
    SELECT 
        ws_item_sk,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450 AND 2452
    GROUP BY 
        ws_item_sk) AS AVG_WS ON RS.ws_item_sk = AVG_WS.ws_item_sk
WHERE 
    c.c_birth_year IS NOT NULL
GROUP BY 
    c.c_customer_id, ca.ca_city, CR.total_returns
HAVING 
    SUM(ss.total_sales) > 1000 OR COALESCE(CR.total_returns, 0) > 5
ORDER BY 
    total_web_sales DESC, total_store_sales DESC;
