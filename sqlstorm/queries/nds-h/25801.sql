WITH RankedSuppliers AS (
    SELECT 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name, 
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
FilteredParts AS (
    SELECT 
        DISTINCT p.p_name, 
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_name
    HAVING COUNT(DISTINCT ps.ps_suppkey) > 5
),
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    rs.nation_name AS supplier_nation,
    rs.s_name AS supplier_name,
    p.p_name AS part_name,
    fp.supplier_count AS available_supplier_count,
    os.total_revenue AS order_revenue,
    CONCAT('Supplier ', rs.s_name, ' from ', rs.nation_name, ' supplies part ', p.p_name, 
           ' with ', fp.supplier_count, ' suppliers. Total revenue from orders is $', 
           ROUND(os.total_revenue, 2)) AS summary_comment
FROM RankedSuppliers rs
JOIN FilteredParts fp ON fp.supplier_count > 0
JOIN part p ON p.p_name LIKE '%part%'
JOIN OrderSummary os ON os.total_revenue > 100000
WHERE rs.rank = 1
ORDER BY os.total_revenue DESC;
