WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) as order_rank
    FROM orders o
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus='O')
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, p.p_comment,
           COALESCE(NULLIF(ps.ps_availqty, 0), NULL) as avail_qty
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size BETWEEN 5 AND 10 AND p.p_retailprice < 100
),
CustomerInfo AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey,
           CASE WHEN c.c_acctbal IS NULL THEN 'No Balance' ELSE CAST(c.c_acctbal AS STRING) END AS acct_balance
    FROM customer c
    WHERE c.c_mktsegment IN ('BUILDING', 'FURNITURE') AND LENGTH(c.c_name) > 10
),
SupplierOrders AS (
    SELECT DISTINCT s.s_suppkey, s.s_name, COUNT(o.o_orderkey) as order_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT ci.c_name, 
       ci.acct_balance,
       rp.o_orderkey,
       rp.o_orderdate,
       rp.o_totalprice,
       fp.p_name,
       fp.p_retailprice,
       sp.s_name,
       sp.order_count,
       CASE WHEN fp.avail_qty IS NULL THEN 'Not Available' ELSE 'Available' END AS availability
FROM RankedOrders rp
JOIN CustomerInfo ci ON ci.c_custkey = rp.o_orderkey % (SELECT COUNT(*) FROM customer)  
LEFT JOIN FilteredParts fp ON fp.p_partkey = rp.o_orderkey % (SELECT COUNT(*) FROM part)  
LEFT JOIN SupplierOrders sp ON sp.order_count > 5  
WHERE rp.order_rank = 1
AND (fp.p_retailprice IS NOT NULL OR rp.o_totalprice > 500)
ORDER BY ci.c_name ASC, rp.o_orderdate DESC
LIMIT 100;