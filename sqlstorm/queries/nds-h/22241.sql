WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS part_rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY s.s_suppkey
),
HighValueNations AS (
    SELECT 
        n.n_nationkey, 
        n.n_name,
        SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING SUM(s.s_acctbal) > 10000
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_linenumber) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT cn.c_custkey) AS customer_count,
    COALESCE(MAX(hv.total_acctbal), 0) AS max_nation_acctbal,
    SUM(od.total_order_value) AS total_order_value,
    AVG(sp.total_sales) AS avg_supplier_sales
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer cn ON n.n_nationkey = cn.c_nationkey
LEFT JOIN HighValueNations hv ON n.n_nationkey = hv.n_nationkey
LEFT JOIN SupplierSales sp ON n.n_nationkey = sp.s_suppkey
LEFT JOIN OrderDetails od ON cn.c_custkey = od.o_orderkey
WHERE r.r_name NOT LIKE '%Unknown%'
GROUP BY r.r_name
HAVING COUNT(DISTINCT cn.c_custkey) > 5
ORDER BY total_order_value DESC, r.r_name;
