WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, c.c_nationkey, 
           ROW_NUMBER() OVER(PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
TopNations AS (
    SELECT n.n_nationkey, n.n_name, SUM(wo.o_totalprice) AS total_revenue
    FROM RankedOrders wo
    JOIN nation n ON wo.c_nationkey = n.n_nationkey
    WHERE wo.order_rank <= 5
    GROUP BY n.n_nationkey, n.n_name
    ORDER BY total_revenue DESC
    LIMIT 5
)
SELECT tn.n_name, sd.s_name, sd.total_supply_cost
FROM TopNations tn
JOIN SupplierDetails sd ON tn.n_nationkey = sd.s_nationkey
ORDER BY tn.total_revenue DESC, sd.total_supply_cost DESC;
