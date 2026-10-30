
WITH AddressDetails AS (
    SELECT
        ca.ca_city AS City,
        ca.ca_state AS State,
        COUNT(DISTINCT c.c_customer_sk) AS CustomerCount,
        COUNT(DISTINCT s.s_store_sk) AS StoreCount
    FROM
        customer_address ca
    LEFT JOIN
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN
        store s ON LOWER(ca.ca_city) = LOWER(s.s_city) AND ca.ca_state = s.s_state
    GROUP BY
        ca.ca_city, ca.ca_state
),
StringBenchmark AS (
    SELECT
        a.City,
        a.State,
        a.CustomerCount,
        a.StoreCount,
        LENGTH(a.City) AS CityLength,
        LENGTH(a.State) AS StateLength,
        CONCAT(a.City, ', ', a.State) AS FullAddress,
        REPLACE(UPPER(a.City), ' ', '_') AS CityWithUnderscores
    FROM
        AddressDetails a
)
SELECT
    *,
    CASE
        WHEN CustomerCount > 0 THEN
            CAST(StoreCount AS STRING) || ' stores serve ' || CAST(CustomerCount AS STRING) || ' customers'
        ELSE
            'No customers in this city/state combination'
    END AS Summary
FROM
    StringBenchmark
WHERE
    CityLength > 3 AND StateLength = 2
ORDER BY
    CustomerCount DESC, StoreCount DESC;
