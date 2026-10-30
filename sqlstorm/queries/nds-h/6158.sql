WITH SupplierCosts AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), 
NationCosts AS (
    SELECT n.n_nationkey, n.n_name, SUM(sc.total_cost) AS nation_total_cost
    FROM nation n
    JOIN SupplierCosts sc ON n.n_nationkey = sc.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
), 
RankedNations AS (
    SELECT n.n_name, nc.nation_total_cost,
           RANK() OVER (ORDER BY nc.nation_total_cost DESC) AS rank
    FROM nation n
    JOIN NationCosts nc ON n.n_nationkey = nc.n_nationkey
)
SELECT rn.rank, rn.n_name, rn.nation_total_cost 
FROM RankedNations rn 
WHERE rn.rank <= 5 
ORDER BY rn.rank;
