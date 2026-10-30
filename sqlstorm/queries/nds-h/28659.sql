
WITH RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_container,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size < 50)
),
FilteredSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'U%'))
),
PartSupplierStats AS (
    SELECT
        ps.ps_partkey,
        COUNT(ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
AggregatedData AS (
    SELECT
        r.r_name,
        SUM(CASE WHEN rp.rn <= 5 THEN 1 ELSE 0 END) AS top_parts_count,
        AVG(pss.total_supply_cost) AS avg_supply_cost
    FROM RankedParts rp
    JOIN PartSupplierStats pss ON rp.p_partkey = pss.ps_partkey
    JOIN region r ON r.r_regionkey IN (SELECT n.n_regionkey FROM nation n JOIN supplier s ON n.n_nationkey = s.s_nationkey WHERE s.s_suppkey IN (SELECT s2.s_suppkey FROM FilteredSuppliers s2))
    GROUP BY r.r_name
)
SELECT
    ad.r_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_revenue,
    MAX(p.ps_supplycost) AS max_supply_cost
FROM AggregatedData ad
JOIN customer c ON c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA') 
JOIN orders o ON o.o_custkey = c.c_custkey
JOIN partsupp p ON p.ps_partkey IN (SELECT rp.p_partkey FROM RankedParts rp WHERE rp.p_brand = 'Brand#2')
GROUP BY ad.r_name
HAVING SUM(o.o_totalprice) > (SELECT AVG(o2.o_totalprice) FROM orders o2)
ORDER BY customer_count DESC, total_revenue DESC;
