WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
),
Awards AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        COUNT(DISTINCT l.l_orderkey) AS line_items
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
    GROUP BY o.o_orderkey, o.o_totalprice
),
SupplierPartInfo AS (
    SELECT 
        s.s_name,
        p.p_mfgr,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size BETWEEN 1 AND 20
    GROUP BY s.s_name, p.p_mfgr
)

SELECT 
    rp.p_partkey,
    rp.p_name,
    COALESCE(ho.o_totalprice, '0.00') AS total_price,
    ai.supplier_count,
    ai.total_supply_cost,
    CASE 
        WHEN rp.rn = 1 THEN 'Top'
        ELSE 'Other' 
    END AS part_rank,
    si.total_avail_qty
FROM RankedParts rp
FULL OUTER JOIN HighValueOrders ho ON rp.p_partkey = ho.o_orderkey
LEFT JOIN Awards ai ON ai.n_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = (SELECT MIN(s.s_nationkey) FROM supplier s))
LEFT JOIN SupplierPartInfo si ON si.p_mfgr = rp.p_name
WHERE rp.p_partkey IS NOT NULL OR ho.o_orderkey IS NOT NULL
ORDER BY rp.p_partkey NULLS LAST, ho.o_totalprice DESC;
