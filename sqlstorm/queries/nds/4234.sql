
WITH RankedSales AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank_quantity
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk, ws_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        d.d_year,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_ship_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_sk, d.d_year
),
StoreRevenue AS (
    SELECT 
        s.s_store_sk,
        SUM(ss_net_paid) AS store_revenue
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
)
SELECT 
    ca_address_sk,
    ca_city,
    ca_state,
    COALESCE(RS.total_quantity, 0) AS total_quantity,
    COALESCE(RS.total_net_paid, 0) AS total_net_paid,
    CS.c_customer_sk,
    CS.order_count,
    CS.total_spent,
    SR.store_revenue
FROM 
    customer_address ca
LEFT JOIN 
    RankedSales RS ON ca.ca_address_sk = RS.ws_item_sk
LEFT JOIN 
    CustomerStats CS ON RS.ws_item_sk = CS.c_customer_sk
LEFT JOIN 
    StoreRevenue SR ON CS.c_customer_sk = SR.s_store_sk
WHERE 
    (CS.order_count > 10 OR SR.store_revenue > 10000)
    AND (CA.ca_state IS NOT NULL AND CA.ca_city IS NOT NULL)
ORDER BY 
    total_net_paid DESC
LIMIT 100;

