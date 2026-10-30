WITH SupplierCustomerInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name AS supplier_name,
        c.c_custkey,
        c.c_name AS customer_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON l.l_partkey = p.p_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE l.l_shipdate >= '1997-01-01' 
      AND l.l_shipdate <= '1997-12-31'
      AND c.c_mktsegment = 'BUILDING'
    GROUP BY s.s_suppkey, s.s_name, c.c_custkey, c.c_name
),
Ranking AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY supplier_name ORDER BY total_revenue DESC) AS revenue_rank
    FROM SupplierCustomerInfo
)
SELECT 
    supplier_name,
    customer_name,
    total_revenue
FROM Ranking
WHERE revenue_rank <= 5
ORDER BY supplier_name, total_revenue DESC;