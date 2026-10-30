
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(CASE WHEN ps.ps_supplycost IS NOT NULL THEN ps.ps_supplycost * ps.ps_availqty ELSE 0 END) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal)
        FROM supplier s2 
        WHERE s2.s_nationkey = s.s_nationkey
    )
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice AS order_total_value,
        c.c_name
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > 10000
)
SELECT 
    r.p_partkey,
    r.p_name,
    r.p_brand,
    r.total_supply_cost,
    r.supplier_count,
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
    COALESCE(SUM(l.l_extendedprice), 0) AS total_extended_price,
    COALESCE(AVG(l.l_discount), 0) AS avg_discount,
    MAX(h.order_total_value) AS order_total_value
FROM RankedParts r
LEFT JOIN lineitem l ON r.p_partkey = l.l_partkey
LEFT JOIN HighValueOrders h ON l.l_orderkey = h.o_orderkey
GROUP BY r.p_partkey, r.p_name, r.p_brand, r.total_supply_cost, r.supplier_count
HAVING supplier_count > 1 AND total_supply_cost IS NOT NULL
ORDER BY total_supply_cost DESC, r.p_name ASC
LIMIT 100;
