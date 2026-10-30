
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws 
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450500
    GROUP BY 
        ws.ws_item_sk
), 
CustomerStats AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_id) AS num_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd.cd_credit_rating) AS highest_credit_rating
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk
), 
AddressRanked AS (
    SELECT 
        ca.ca_city,
        COUNT(c.c_customer_id) AS customer_count,
        RANK() OVER (ORDER BY COUNT(c.c_customer_id) DESC) AS city_rank
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_city
)
SELECT 
    a.ca_city,
    a.customer_count,
    cs.num_customers,
    cs.avg_purchase_estimate,
    s.total_sales,
    CASE 
        WHEN s.sales_rank <= 5 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS seller_status
FROM 
    AddressRanked a
LEFT JOIN 
    CustomerStats cs ON a.city_rank <= 5
LEFT JOIN 
    SalesData s ON a.city_rank <= 5 AND s.total_sales > 1000
WHERE 
    a.customer_count > 10
ORDER BY 
    a.customer_count DESC, s.total_sales DESC;
