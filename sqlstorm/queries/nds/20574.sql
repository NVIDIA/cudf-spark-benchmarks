WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS store_sales,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS web_sales,
        COUNT(DISTINCT CASE WHEN sr.sr_item_sk IS NOT NULL THEN sr.sr_ticket_number END) AS store_returns_count,
        COUNT(DISTINCT CASE WHEN wr.wr_item_sk IS NOT NULL THEN wr.wr_order_number END) AS web_returns_count
    FROM 
        customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        CASE 
            WHEN cd.cd_dep_count > 2 THEN 'Large Family'
            WHEN cd.cd_dep_count BETWEEN 1 AND 2 THEN 'Small Family'
            ELSE 'Single' 
        END AS family_size
    FROM
        customer_demographics cd
),
SalesMetrics AS (
    SELECT
        cs.c_customer_id,
        cs.store_sales,
        cs.web_sales,
        cs.store_returns_count,
        cs.web_returns_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.family_size,
        (cs.store_sales + cs.web_sales) AS total_sales
    FROM 
        CustomerSales cs
    JOIN 
        CustomerDemographics cd ON cs.c_customer_id = cd.cd_gender 
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY family_size ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesMetrics
)
SELECT 
    r.c_customer_id,
    r.total_sales,
    r.cd_gender,
    r.cd_marital_status,
    r.sales_rank
FROM 
    RankedSales r
WHERE 
    r.sales_rank = 1
    AND r.total_sales > (
        SELECT COALESCE(AVG(total_sales), 0) * 1.1 FROM RankedSales
        WHERE family_size = r.family_size
        AND r.cd_gender IS NOT NULL
    )
ORDER BY 
    r.total_sales DESC
LIMIT 10;