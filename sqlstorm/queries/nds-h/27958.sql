WITH SupplierDetails AS (
    SELECT s.s_name, s.s_address, n.n_name AS nation_name, COUNT(ps.ps_partkey) AS part_supply_count
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name, s.s_address, n.n_name
),
StringMetrics AS (
    SELECT s.s_name,
           LENGTH(s.s_name) AS name_length,
           LENGTH(s.s_address) AS address_length,
           REGEXP_REPLACE(n.n_name, '[^[:alpha:]]', '') AS cleaned_nation_name,
           LENGTH(REGEXP_REPLACE(n.n_name, '[^[:alpha:]]', '')) AS cleaned_nation_length
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
CombinedMetrics AS (
    SELECT sd.s_name,
           sd.s_address,
           sd.nation_name,
           sd.part_supply_count,
           sm.name_length,
           sm.address_length,
           sm.cleaned_nation_name,
           sm.cleaned_nation_length,
           CONCAT(sd.s_name, ' from ', sd.s_address, ' supplies parts from ', sd.nation_name) AS description
    FROM SupplierDetails sd
    JOIN StringMetrics sm ON sd.s_name = sm.s_name
)
SELECT description, 
       part_supply_count, 
       name_length, 
       address_length, 
       cleaned_nation_length 
FROM CombinedMetrics 
WHERE part_supply_count > 5 
ORDER BY part_supply_count DESC, name_length DESC;
