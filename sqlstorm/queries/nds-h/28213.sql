
WITH StringProcessing AS (
    SELECT 
        p.p_partkey,
        CONCAT(SUBSTRING(p.p_name, 1, 20), '...', SUBSTRING(p.p_name, LENGTH(p.p_name) - 19, 20)) AS p_name_trim,
        REPLACE(p.p_comment, 'original', 'replaced') AS p_comment_replaced,
        UPPER(p.p_mfgr) AS p_mfgr_upper,
        LOWER(p.p_container) AS p_container_lower,
        LENGTH(p.p_name) AS p_name_length,
        CHAR_LENGTH(p.p_comment) AS p_comment_length
    FROM part p
    WHERE p.p_retailprice > 100.00
),
AggregatedData AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        SUM(CAST(ps.ps_availqty AS DECIMAL)) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE n.n_name LIKE '%United%'
    GROUP BY n.n_name
)
SELECT 
    sp.p_partkey,
    sp.p_name_trim,
    sp.p_comment_replaced,
    ad.total_suppliers,
    ad.total_avail_qty,
    ad.total_supply_cost
FROM StringProcessing sp
JOIN AggregatedData ad ON ad.total_suppliers > 5 
ORDER BY sp.p_name_length DESC, ad.total_supply_cost DESC
LIMIT 10;
