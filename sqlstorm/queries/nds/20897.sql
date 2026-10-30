
WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_quantity) DESC) AS rank_quantity
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
), BestSellingItems AS (
    SELECT 
        cs_item_sk,
        total_quantity,
        total_net_profit
    FROM 
        RankedSales
    WHERE 
        rank_quantity <= 10
), CustomerReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
), ReturnsStats AS (
    SELECT 
        bsi.cs_item_sk,
        bsi.total_quantity,
        bsi.total_net_profit,
        COALESCE(cr.total_returns, 0) AS total_returns,
        CASE 
            WHEN bsi.total_quantity > 0 THEN (COALESCE(cr.total_returns, 0) * 100.0 / bsi.total_quantity)
            ELSE NULL 
        END AS return_rate
    FROM 
        BestSellingItems bsi
    LEFT JOIN 
        CustomerReturns cr ON bsi.cs_item_sk = cr.cr_item_sk
), CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE 
        cd_marital_status IS NOT NULL
    GROUP BY 
        cd_gender, 
        cd_marital_status
)
SELECT 
    r.cs_item_sk,
    r.total_quantity,
    r.total_net_profit,
    r.total_returns,
    r.return_rate,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count
FROM 
    ReturnsStats r
CROSS JOIN 
    CustomerDemographics cd
WHERE 
    r.return_rate IS NOT NULL
ORDER BY 
    r.return_rate DESC, 
    r.total_net_profit DESC
LIMIT 100;
