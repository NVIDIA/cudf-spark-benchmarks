
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_ext_sales_price DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 30
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(ws.ws_item_sk) AS item_count
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL
        AND c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        c.c_customer_id
),
SalesData AS (
    SELECT 
        COALESCE(cs.cs_item_sk, ss.ss_item_sk) AS item_sk,
        SUM(COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0)) AS total_sales,
        SUM(COALESCE(cs.cs_quantity, 0) + COALESCE(ss.ss_quantity, 0)) AS total_quantity
    FROM 
        catalog_sales cs
    FULL OUTER JOIN 
        store_sales ss ON cs.cs_item_sk = ss.ss_item_sk
    GROUP BY 
        COALESCE(cs.cs_item_sk, ss.ss_item_sk)
)
SELECT 
    ca.ca_address_id,
    cd.cd_gender,
    cd.cd_marital_status,
    AVG(cp.total_spent) AS avg_spending,
    (SELECT AVG(total_quantity) 
     FROM SalesData 
     WHERE item_sk IN (SELECT ws_item_sk FROM RankedSales WHERE sales_rank = 1)) AS avg_top_item_sales,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    CustomerPurchases AS cp ON c.c_customer_id = cp.c_customer_id
LEFT JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_country = 'USA'
    AND cd.cd_gender = 'F'
    AND (NOT EXISTS (SELECT 1 FROM catalog_returns WHERE cr_returning_customer_sk = c.c_customer_sk)
         OR EXISTS (SELECT 1 FROM web_returns WHERE wr_returning_customer_sk = c.c_customer_sk))
GROUP BY 
    ca.ca_address_id, cd.cd_gender, cd.cd_marital_status
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY 
    avg_spending DESC
LIMIT 100;
