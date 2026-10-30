
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_by_price
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_value,
        COUNT(*) AS part_count,
        MAX(s.s_acctbal) AS max_balance
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
RegionNations AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT 
    r.r_name,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    RANK() OVER (PARTITION BY r.r_name ORDER BY ss.total_value DESC) AS supplier_rank,
    ro.o_orderdate,
    ro.o_totalprice,
    CASE 
        WHEN ro.o_totalprice > 1000 THEN 'High Value'
        ELSE 'Regular'
    END AS order_value_category
FROM RegionNations r
LEFT JOIN SupplierSummary ss ON r.nation_count > 5
LEFT JOIN RankedOrders ro ON ro.o_orderkey IN (
    SELECT DISTINCT l.l_orderkey
    FROM lineitem l
    WHERE l.l_quantity > 50 AND l.l_discount < 0.05
    GROUP BY l.l_orderkey
    HAVING SUM(l.l_extendedprice) > 2000
)
LEFT JOIN supplier s ON s.s_suppkey = ss.s_suppkey AND ss.part_count > 2
WHERE 
    (s.s_acctbal IS NULL OR s.s_acctbal > 500) AND 
    ro.o_orderdate IS NOT NULL
GROUP BY r.r_name, s.s_name, ro.o_orderdate, ro.o_totalprice, ss.total_value
ORDER BY r.r_name, supplier_rank;
