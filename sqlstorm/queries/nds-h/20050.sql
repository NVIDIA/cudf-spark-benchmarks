WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 50
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS distinct_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal) FROM supplier s2
    )
    GROUP BY s.s_suppkey, s.s_name
),
OrderQuantities AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(DISTINCT l.l_partkey) AS distinct_line_items
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY o.o_orderkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    COALESCE(MAX(rs.p_retailprice), 0) AS max_price_part,
    SUM(oss.total_quantity) AS total_ordered_quantity,
    ss.total_supply_cost,
    ss.distinct_parts
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN RankedParts rs ON n.n_nationkey = rs.p_partkey AND rs.rn <= 5
LEFT JOIN SupplierStats ss ON n.n_nationkey = ss.s_suppkey
FULL OUTER JOIN OrderQuantities oss ON ss.s_suppkey = oss.o_orderkey
GROUP BY r.r_name, ss.total_supply_cost, ss.distinct_parts
HAVING COUNT(n.n_nationkey) > 1 OR ss.total_supply_cost IS NOT NULL
ORDER BY r.r_name, total_ordered_quantity DESC
LIMIT 10;
