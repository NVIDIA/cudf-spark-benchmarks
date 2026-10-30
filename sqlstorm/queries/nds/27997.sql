
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), FilteredCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_purchase_estimate
    FROM RankedCustomers AS rc
    WHERE rc.purchase_rank <= 5
), CustomerAddresses AS (
    SELECT 
        f.c_customer_sk,
        CONCAT_WS(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, 
                  COALESCE(ca.ca_suite_number, ''), 
                  ca.ca_city, 
                  ca.ca_state, 
                  ca.ca_zip) AS full_address
    FROM FilteredCustomers AS f
    JOIN customer_address AS ca ON f.c_customer_sk = ca.ca_address_sk
), AddressCharacterCounts AS (
    SELECT 
        c.c_customer_sk,
        LENGTH(c.full_address) AS address_length,
        CHAR_LENGTH(c.full_address) AS address_char_length,
        REGEXP_REPLACE(c.full_address, '[^a-zA-Z]', '') AS letters_only,
        LENGTH(REGEXP_REPLACE(c.full_address, '[^a-zA-Z]', '')) AS letter_count
    FROM CustomerAddresses AS c
)
SELECT 
    a.c_customer_sk,
    a.address_length,
    a.address_char_length,
    a.letter_count
FROM AddressCharacterCounts AS a
WHERE a.letter_count > 0
ORDER BY a.c_customer_sk;
