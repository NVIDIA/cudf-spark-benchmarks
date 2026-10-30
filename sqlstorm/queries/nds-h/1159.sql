WITH SupplierOrders AS (
    SELECT 
        s.s_name,
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY s.s_name, n.n_name
),
RankedSuppliers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY nation_name ORDER BY total_revenue DESC) AS revenue_rank
    FROM SupplierOrders
)
SELECT 
    s.s_name,
    s.nation_name,
    s.total_revenue,
    CASE 
        WHEN s.revenue_rank <= 3 THEN 'Top Supplier'
        ELSE 'Other Supplier'
    END AS supplier_type
FROM RankedSuppliers s
WHERE s.total_revenue IS NOT NULL
AND s.nation_name IS NOT NULL
ORDER BY s.nation_name, s.total_revenue DESC;
