WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_by_price
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 40
),
FilteredSuppliers AS (
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
TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        RANK() OVER (ORDER BY COUNT(DISTINCT s.s_suppkey) DESC) AS nation_rank
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING COUNT(DISTINCT s.s_suppkey) > 3
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
        COUNT(l.l_orderkey) AS line_count,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT 
    rp.p_name,
    fs.s_name AS top_supplier,
    on_summary.order_value,
    on_summary.line_count,
    tn.n_name AS top_nation
FROM RankedParts rp
LEFT JOIN FilteredSuppliers fs ON rp.p_partkey = fs.s_suppkey
INNER JOIN TopNations tn ON fs.nation_name = tn.n_name
RIGHT JOIN OrderSummary on_summary ON on_summary.line_count > 0 AND rp.rank_by_price <= 5
WHERE rp.rank_by_price IS NOT NULL
ORDER BY on_summary.order_value DESC, rp.p_retailprice ASC
LIMIT 10 OFFSET 5;
