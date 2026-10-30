
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_gender
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ReturnStatistics AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_tax) AS total_return_tax
    FROM 
        store_returns 
    GROUP BY 
        sr_customer_sk
),
WebReturnStatistics AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(wr_order_number) AS total_web_returns,
        SUM(wr_return_quantity) AS total_web_return_quantity,
        SUM(wr_return_amt) AS total_web_return_amt,
        SUM(wr_return_tax) AS total_web_return_tax
    FROM 
        web_returns 
    GROUP BY 
        wr_returning_customer_sk
),
CombinedReturns AS (
    SELECT 
        rc.c_customer_id,
        COALESCE(rs.total_returns, 0) AS total_in_store_returns,
        COALESCE(wr.total_web_returns, 0) AS total_web_returns,
        (COALESCE(rs.total_returns, 0) + COALESCE(wr.total_web_returns, 0)) AS total_returns,
        (COALESCE(rs.total_return_quantity, 0) + COALESCE(wr.total_web_return_quantity, 0)) AS total_return_quantity
    FROM 
        RankedCustomers rc
    LEFT JOIN 
        ReturnStatistics rs ON rc.c_customer_sk = rs.sr_customer_sk
    LEFT JOIN 
        WebReturnStatistics wr ON rc.c_customer_sk = wr.wr_returning_customer_sk
    WHERE 
        rc.rank_by_gender <= 5 
)
SELECT 
    cb.c_customer_id,
    cb.total_in_store_returns,
    cb.total_web_returns,
    cb.total_returns,
    cb.total_return_quantity,
    CASE 
        WHEN cb.total_return_quantity > 0 THEN 
            (cb.total_in_store_returns * 100.0 / NULLIF(cb.total_return_quantity, 0))
        ELSE 
            NULL 
    END AS percentage_in_store_returns,
    CONCAT('Customer ', cb.c_customer_id, ' has returned a total of ', CAST(cb.total_return_quantity AS STRING), ' items.') AS return_message,
    (SELECT 
        MAX(total_returns) 
     FROM 
        CombinedReturns) AS max_total_returns
FROM 
    CombinedReturns cb
ORDER BY 
    cb.total_returns DESC;
