
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS rn
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
), 
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_marital_status,
        cd.cd_gender,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_purchases,
        MAX(ws.ws_sales_price) AS max_purchase_price,
        AVG(CASE WHEN ws.ws_net_paid > 20 THEN ws.ws_net_paid ELSE NULL END) AS avg_high_spender
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_marital_status, cd.cd_gender
), 
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        cs.total_purchases,
        cs.max_purchase_price,
        cs.avg_high_spender,
        RANK() OVER (ORDER BY cs.total_purchases DESC) AS purchase_rank
    FROM 
        CustomerStats cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.avg_high_spender IS NOT NULL
)

SELECT 
    c.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    tc.total_purchases,
    tc.max_purchase_price,
    tc.avg_high_spender,
    CASE 
        WHEN tc.purchase_rank <= 10 THEN 'Top 10 Customers'
        ELSE 'Regular Customers' 
    END AS customer_category,
    COALESCE(SUM(sr_returned.returned), 0) AS total_returns
FROM 
    TopCustomers tc
JOIN 
    customer c ON tc.c_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN (
    SELECT 
        sr_customer_sk AS returned,
        SUM(sr_return_quantity) AS returned_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
) sr_returned ON sr_returned.returned = c.c_customer_sk
GROUP BY 
    c.c_customer_id, ca.ca_city, ca.ca_state, tc.total_purchases, 
    tc.max_purchase_price, tc.avg_high_spender, tc.purchase_rank
HAVING 
    COUNT(*) > 1 OR SUM(sr_returned.returned) IS NULL
ORDER BY 
    total_returns DESC NULLS LAST, 
    purchase_rank;
