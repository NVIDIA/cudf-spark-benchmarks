
WITH  SalesCTE AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_net_profit DESC) AS rn
    FROM 
        web_sales
    WHERE
        ws_sold_date_sk > (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state,
        SUM(CASE WHEN ws_quantity > 0 THEN ws_quantity ELSE 0 END) AS total_purchases
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_current_cdemo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate, 
        cd.cd_credit_rating, 
        ca.ca_city, 
        ca.ca_state
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.total_purchases,
        ROW_NUMBER() OVER (ORDER BY c.total_purchases DESC) AS rank
    FROM 
        CustomerDetails c
    WHERE 
        c.total_purchases > (SELECT AVG(total_purchases) FROM CustomerDetails)
)
SELECT 
    tc.c_customer_sk,
    cd.ca_city,
    cd.ca_state,
    tc.total_purchases,
    sd.ss_quantity,
    sd.ss_sales_price,
    sd.ss_net_profit
FROM 
    TopCustomers tc
JOIN 
    store_sales sd ON tc.c_customer_sk = sd.ss_customer_sk
JOIN 
    customer_address cd ON tc.c_customer_sk = cd.ca_address_sk
WHERE 
    tc.rank <= 10 AND 
    sd.ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    AND (sd.ss_sales_price - sd.ss_net_profit) > 0
ORDER BY 
    tc.total_purchases DESC, 
    cd.ca_city, 
    cd.ca_state;
