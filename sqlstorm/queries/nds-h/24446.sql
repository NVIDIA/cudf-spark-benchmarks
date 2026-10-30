
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT ps.ps_availqty FROM partsupp ps WHERE ps.ps_supplycost < 100)
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerAggregates AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        AVG(CASE WHEN o.o_orderstatus = 'O' THEN 1 ELSE NULL END) AS avg_order_status
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    r.r_name AS region_name,
    ca.c_name AS customer_name,
    sd.s_name AS supplier_name,
    pp.p_name AS part_name,
    pp.p_retailprice AS part_price,
    ca.total_spent AS customer_spending,
    sd.total_supplycost AS supplier_cost,
    CASE 
        WHEN ca.avg_order_status IS NULL THEN 'No Orders'
        WHEN ca.avg_order_status < 1 THEN 'Pending'
        ELSE 'Completed'
    END AS order_status_summary
FROM RankedParts pp
FULL OUTER JOIN SupplierDetails sd ON sd.total_parts > 5
LEFT JOIN CustomerAggregates ca ON ca.order_count > 0
JOIN nation n ON n.n_nationkey = (SELECT MIN(c.c_nationkey) FROM customer c WHERE c.c_name LIKE '%Corp%')
JOIN region r ON r.r_regionkey = n.n_regionkey
WHERE pp.rn <= 3
AND sd.total_supplycost IS NOT NULL
ORDER BY region_name, customer_name, supplier_name;
