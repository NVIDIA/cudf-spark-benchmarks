
WITH CustomerReturnSummary AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT sr_ticket_number) AS total_store_returns,
        SUM(sr_return_amt) AS total_store_return_amt,
        SUM(sr_return_quantity) AS total_store_return_quantity
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
),
CatalogReturnSummary AS (
    SELECT 
        cr_returning_customer_sk,
        COUNT(DISTINCT cr_order_number) AS total_catalog_returns,
        SUM(cr_return_amount) AS total_catalog_return_amt,
        SUM(cr_return_quantity) AS total_catalog_return_quantity
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
WebReturnSummary AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(DISTINCT wr_order_number) AS total_web_returns,
        SUM(wr_return_amt) AS total_web_return_amt,
        SUM(wr_return_quantity) AS total_web_return_quantity
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
ReturnSummary AS (
    SELECT 
        cus.c_customer_id,
        COALESCE(st.total_store_returns, 0) AS total_store_returns,
        COALESCE(st.total_store_return_amt, 0) AS total_store_return_amt,
        COALESCE(ct.total_catalog_returns, 0) AS total_catalog_returns,
        COALESCE(ct.total_catalog_return_amt, 0) AS total_catalog_return_amt,
        COALESCE(wr.total_web_returns, 0) AS total_web_returns,
        COALESCE(wr.total_web_return_amt, 0) AS total_web_return_amt
    FROM 
        CustomerReturnSummary cus
    LEFT JOIN 
        CustomerReturnSummary st ON cus.c_customer_id = st.c_customer_id
    LEFT JOIN 
        CatalogReturnSummary ct ON cus.c_customer_id = CAST(ct.cr_returning_customer_sk AS CHAR(16))
    LEFT JOIN 
        WebReturnSummary wr ON cus.c_customer_id = CAST(wr.wr_returning_customer_sk AS CHAR(16))
)
SELECT 
    r.c_customer_id,
    r.total_store_returns,
    r.total_store_return_amt,
    r.total_catalog_returns,
    r.total_catalog_return_amt,
    r.total_web_returns,
    r.total_web_return_amt,
    CASE 
        WHEN r.total_store_return_amt + r.total_catalog_return_amt + r.total_web_return_amt = 0 
        THEN NULL 
        ELSE (r.total_store_return_amt + r.total_catalog_return_amt + r.total_web_return_amt) / 
             NULLIF(COALESCE(stored_aggregates.total_aggregate_quantity, 1), 0)
    END AS return_ratio
FROM 
    ReturnSummary r
LEFT JOIN (
    SELECT 
        COUNT(sr_return_quantity) AS total_aggregate_quantity
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
) stored_aggregates ON TRUE
WHERE 
    r.total_store_returns > 0 
    OR r.total_catalog_returns > 0 
    OR r.total_web_returns > 0
ORDER BY 
    r.total_store_return_amt DESC;
