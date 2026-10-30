
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 365
),
TopSales AS (
    SELECT
        r.ws_item_sk,
        SUM(r.ws_quantity) AS total_quantity_sold,
        AVG(r.ws_sales_price) AS avg_sales_price
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank <= 5
    GROUP BY 
        r.ws_item_sk
),
CustomerCounts AS (
    SELECT
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    ca.ca_city,
    SUM(ts.total_quantity_sold) AS total_quantity_sold,
    COUNT(DISTINCT cc.cd_demo_sk) AS total_customers,
    MAX(ts.avg_sales_price) AS max_avg_sales_price
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    TopSales ts ON ts.ws_item_sk IN (
        SELECT i.i_item_sk 
        FROM item i 
        WHERE i.i_category = 'Electronics' 
          AND i.i_brand IN (SELECT p.p_promo_name FROM promotion p WHERE p.p_discount_active = 'Y')
    )
LEFT JOIN 
    CustomerCounts cc ON c.c_current_cdemo_sk = cc.cd_demo_sk
WHERE 
    ca.ca_state IS NOT NULL
GROUP BY 
    ca.ca_city
HAVING 
    SUM(ts.total_quantity_sold) > 100
ORDER BY 
    total_quantity_sold DESC
LIMIT 10;
