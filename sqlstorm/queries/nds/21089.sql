
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
AggregatedReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MIN(cd_credit_rating) AS min_credit_rating,
        MAX(cd_credit_rating) AS max_credit_rating
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
)
SELECT 
    ca.ca_city,
    COALESCE(r.total_quantity, 0) AS total_sales_quantity,
    COALESCE(r.total_sales, 0) AS total_sales_amount,
    COALESCE(a.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(a.total_return_amount, 0) AS total_return_amount,
    c.cd_gender,
    c.customer_count,
    c.avg_purchase_estimate,
    CASE 
        WHEN r.total_sales > 1000 THEN 'High Performer' 
        WHEN r.total_sales BETWEEN 500 AND 1000 THEN 'Medium Performer' 
        ELSE 'Low Performer' 
    END AS performance_label
FROM 
    customer_address ca
LEFT JOIN 
    RankedSales r ON r.ws_item_sk = ca.ca_address_sk
LEFT JOIN 
    AggregatedReturns a ON a.wr_item_sk = r.ws_item_sk
LEFT JOIN 
    CustomerStats c ON c.cd_gender = 
        (CASE WHEN r.total_sales IS NULL THEN 'M' ELSE 'F' END)
WHERE 
    ca.ca_state IN (SELECT DISTINCT ca_state FROM customer_address WHERE ca_country = 'USA')
    AND (r.total_sales IS NOT NULL OR a.total_return_quantity IS NOT NULL)
ORDER BY 
    ca.ca_city,  
    performance_label
LIMIT 50 OFFSET 0;
