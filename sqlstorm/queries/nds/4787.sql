
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
AggregateReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(rs.total_returned, 0) AS total_returned,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount,
    cd.gender,
    cd.marital_status,
    cd.customer_count
FROM 
    item i
LEFT JOIN 
    AggregateReturns rs ON i.i_item_sk = rs.cr_item_sk
JOIN 
    CustomerDemographics cd ON cd.cd_demo_sk IN (SELECT DISTINCT c.c_current_cdemo_sk FROM customer c WHERE c.c_current_addr_sk IS NOT NULL)
WHERE 
    i.i_item_sk IN (SELECT ws.ws_item_sk FROM RankedSales ws WHERE ws.sales_rank <= 10)
ORDER BY 
    total_returned DESC, total_return_amount DESC;
