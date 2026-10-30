
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerAddressDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_addr_sk,
        a.ca_state,
        d.d_year,
        d.d_month_seq,
        CASE 
            WHEN a.ca_state IS NULL THEN 'UNKNOWN' 
            ELSE a.ca_state 
        END AS address_state
    FROM 
        customer c
    LEFT JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    LEFT JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
HighValueCustomers AS (
    SELECT 
        csd.ws_bill_customer_sk,
        csd.total_profit,
        cad.address_state,
        cad.d_year,
        cad.d_month_seq
    FROM 
        SalesData csd
    JOIN 
        CustomerAddressDetails cad ON csd.ws_bill_customer_sk = cad.c_customer_sk
    WHERE 
        csd.order_count > 5 AND csd.total_profit > 10000
)
SELECT 
    hv.ws_bill_customer_sk,
    hv.total_profit,
    CONCAT('Profit: ', CAST(hv.total_profit AS STRING), ' USD') AS formatted_profit,
    hv.address_state,
    hv.d_year,
    hv.d_month_seq
FROM 
    HighValueCustomers hv
WHERE 
    hv.address_state IS NOT NULL
    AND hv.d_year = (SELECT MAX(d_year) FROM CustomerAddressDetails WHERE d_year IS NOT NULL)
ORDER BY 
    hv.total_profit DESC
LIMIT 10;
