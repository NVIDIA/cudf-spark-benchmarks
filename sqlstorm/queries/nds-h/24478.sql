WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        DENSE_RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank,
        CASE 
            WHEN p.p_retailprice IS NULL THEN 'Unknown'
            WHEN p.p_retailprice < 100 THEN 'Low Price'
            WHEN p.p_retailprice BETWEEN 100 AND 500 THEN 'Medium Price'
            ELSE 'High Price'
        END AS price_category
    FROM part p
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
RelevantOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        COUNT(DISTINCT l.l_orderkey) AS lineitem_count
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate > '1997-01-01'
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate
)
SELECT 
    r.p_partkey,
    r.p_name,
    r.price_category,
    ts.s_name AS supplier_name,
    ro.o_orderkey,
    ro.o_totalprice,
    ro.lineitem_count
FROM RankedParts r
JOIN TopSuppliers ts ON r.price_rank = 1 AND ts.rn <= 5
LEFT JOIN RelevantOrders ro ON ro.lineitem_count > 0
WHERE (r.p_retailprice IS NOT NULL AND r.p_retailprice > 200)
  OR (r.p_name LIKE '%fragile%' AND ts.s_acctbal < 1000)
ORDER BY r.price_category DESC, ts.s_name ASC
LIMIT 10;