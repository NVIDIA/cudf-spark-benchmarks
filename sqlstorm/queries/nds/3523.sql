
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 24100 AND 24130
),
HighValueItems AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_net_profit) AS total_net_profit
    FROM 
        SalesData sd
    WHERE 
        sd.sales_rank <= 10
    GROUP BY 
        sd.ws_item_sk
),
RetailDetails AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        SUM(ss.ss_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    WHERE 
        ca.ca_state IN ('CA', 'TX')
    GROUP BY 
        c.c_customer_sk, ca.ca_city, ca.ca_state
),
FinalSalesReport AS (
    SELECT 
        hvi.ws_item_sk,
        rd.ca_city,
        rd.ca_state,
        rd.total_spent,
        hvi.total_net_profit,
        RANK() OVER (ORDER BY hvi.total_net_profit DESC) AS item_rank
    FROM 
        HighValueItems hvi
    JOIN 
        RetailDetails rd ON hvi.ws_item_sk = rd.c_customer_sk
)

SELECT 
    fsr.item_rank,
    fsr.ws_item_sk,
    fsr.ca_city,
    fsr.ca_state,
    fsr.total_spent,
    fsr.total_net_profit
FROM 
    FinalSalesReport fsr
WHERE 
    fsr.total_spent IS NOT NULL
    AND fsr.total_net_profit IS NOT NULL
ORDER BY 
    fsr.item_rank, fsr.total_spent DESC
LIMIT 100;
