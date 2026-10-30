WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
NationDetails AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
RankedSuppliers AS (
    SELECT sd.s_suppkey, sd.s_name, nd.n_name, sd.total_cost,
           RANK() OVER (PARTITION BY nd.n_name ORDER BY sd.total_cost DESC) AS cost_rank
    FROM SupplierDetails sd
    JOIN NationDetails nd ON sd.s_nationkey = nd.n_nationkey
)
SELECT rs.n_name AS nation_name, rs.s_name AS supplier_name, rs.total_cost
FROM RankedSuppliers rs
WHERE rs.cost_rank <= 5
ORDER BY rs.n_name, rs.total_cost DESC;
