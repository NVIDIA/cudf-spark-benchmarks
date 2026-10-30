
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS order_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_current_addr_sk IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_customer_id
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk, 
        cs.c_customer_id,
        cs.total_orders,
        cs.total_net_profit
    FROM CustomerSales cs
    WHERE cs.total_net_profit > (
        SELECT AVG(total_net_profit) 
        FROM CustomerSales
    )
),
AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY COUNT(c.c_customer_sk) DESC) AS city_rank
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_zip
)
SELECT 
    hvc.c_customer_id,
    hvc.total_orders,
    hvc.total_net_profit,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip
FROM HighValueCustomers hvc
LEFT JOIN AddressDetails ad ON hvc.c_customer_sk = ad.ca_address_sk
WHERE ad.city_rank <= 5
ORDER BY hvc.total_net_profit DESC, hvc.total_orders DESC;
