
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
popular_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        SUM(ss.ss_quantity) AS total_sold
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_item_id, i.i_item_desc
    ORDER BY total_sold DESC
    LIMIT 10
),
returns_summary AS (
    SELECT 
        sr.sr_item_sk,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_returned_amt
    FROM store_returns sr
    GROUP BY sr.sr_item_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    pi.i_item_id,
    pi.i_item_desc,
    pi.total_sold,
    rs.total_returns,
    rs.total_returned_amt
FROM customer_info ci
JOIN popular_items pi ON pi.i_item_sk IN (
    SELECT i.i_item_sk
    FROM item i
    JOIN returns_summary rs ON i.i_item_sk = rs.sr_item_sk
    WHERE rs.total_returns > 0
)
LEFT JOIN returns_summary rs ON pi.i_item_sk = rs.sr_item_sk
ORDER BY pi.total_sold DESC, rs.total_returned_amt DESC;
