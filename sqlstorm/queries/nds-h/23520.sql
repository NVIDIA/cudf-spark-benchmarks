
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT p2.p_size FROM part p2 WHERE p2.p_retailprice > 100)
), RegionSupplier AS (
    SELECT 
        r.r_regionkey,
        COUNT(s.s_suppkey) AS supplier_count
    FROM region r
    LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
    GROUP BY r.r_regionkey
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING SUM(o.o_totalprice) > (SELECT AVG(o2.o_totalprice) FROM orders o2)
), LineItemSummary AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_tax) AS average_tax
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN DATE '1998-10-01' - INTERVAL '1 year' AND DATE '1998-10-01'
    GROUP BY l.l_partkey
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_retailprice,
    COALESCE(rs.supplier_count, 0) AS supplier_count,
    COALESCE(co.total_spent, 0) AS customer_spending,
    lis.total_revenue,
    CASE WHEN lis.average_tax IS NULL THEN 'No Data' ELSE CAST(lis.average_tax AS STRING) END AS average_tax
FROM RankedParts rp
LEFT JOIN RegionSupplier rs ON rp.p_partkey % 10 = rs.r_regionkey
LEFT JOIN CustomerOrders co ON co.c_custkey = rp.p_partkey
LEFT JOIN LineItemSummary lis ON lis.l_partkey = rp.p_partkey
ORDER BY rp.p_retailprice DESC, rp.p_name ASC
LIMIT 100
