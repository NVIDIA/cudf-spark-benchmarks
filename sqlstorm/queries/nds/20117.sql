
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS ranked_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
TopSellingItems AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS total_sales,
        AVG(rs.ws_sales_price) AS avg_price
    FROM 
        RankedSales rs
    WHERE 
        rs.ranked_price <= 5
    GROUP BY 
        rs.ws_item_sk
),
CustomerWithHighReturns AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM 
        store_returns sr
    WHERE 
        sr.sr_return_quantity > 0
    GROUP BY 
        sr.sr_customer_sk
    HAVING 
        SUM(sr.sr_return_amt) > (SELECT AVG(sr2.sr_return_amt) FROM store_returns sr2 WHERE sr2.sr_return_quantity > 0)
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        c.c_customer_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender IS NOT NULL OR cd.cd_marital_status IS NOT NULL
),
FinalAnalysis AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ts.total_sales) AS total_sales_count,
        COUNT(DISTINCT ch.return_count) AS high_return_customers
    FROM 
        TopSellingItems ts
    LEFT JOIN 
        CustomerWithHighReturns ch ON ts.ws_item_sk = ch.sr_customer_sk
    JOIN 
        CustomerDemographics cd ON cd.c_customer_sk = ch.sr_customer_sk
    GROUP BY 
        cd.cd_gender,
        cd.cd_marital_status
)
SELECT 
    fa.cd_gender,
    fa.cd_marital_status,
    fa.total_sales_count,
    COALESCE(fa.high_return_customers, 0) AS high_return_customers,
    CASE 
        WHEN fa.high_return_customers IS NOT NULL AND fa.total_sales_count <> 0 THEN
            ROUND((fa.high_return_customers * 1.0 / fa.total_sales_count) * 100, 2)
        ELSE 
            0 
    END AS return_rate
FROM 
    FinalAnalysis fa
WHERE 
    fa.total_sales_count > 100
ORDER BY 
    fa.cd_gender,
    fa.cd_marital_status;
