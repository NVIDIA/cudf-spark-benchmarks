WITH SupplierLineItems AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT sli.s_suppkey, sli.s_name, sli.total_revenue,
           RANK() OVER (ORDER BY sli.total_revenue DESC) AS revenue_rank
    FROM SupplierLineItems sli
)
SELECT r.s_suppkey, r.s_name, r.total_revenue
FROM RankedSuppliers r
WHERE r.revenue_rank <= 10;
