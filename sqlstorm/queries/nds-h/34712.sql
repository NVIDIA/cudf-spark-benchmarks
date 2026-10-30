WITH  SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS supply_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
),
TopSuppliers AS (
    SELECT s.n_nationkey, SUM(sc.ps_availqty * sc.ps_supplycost) AS total_supply_cost
    FROM SupplyChain sc
    JOIN nation s ON sc.s_nationkey = s.n_nationkey
    WHERE sc.supply_rank <= 5
    GROUP BY s.n_nationkey
),
OrderSummary AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_custkey
),
CustomerRevenue AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, COALESCE(os.total_revenue, 0) AS total_revenue
    FROM customer c
    LEFT JOIN OrderSummary os ON c.c_custkey = os.o_custkey
),
FinalReport AS (
    SELECT cn.n_name AS nation_name, SUM(cr.total_revenue) AS total_revenue,
           SUM(ts.total_supply_cost) AS total_supply_cost,
           CASE 
               WHEN SUM(cr.total_revenue) > SUM(ts.total_supply_cost) THEN 'Profitable'
               ELSE 'Not Profitable'
           END AS profitability
    FROM CustomerRevenue cr
    JOIN nation cn ON cr.c_nationkey = cn.n_nationkey
    LEFT JOIN TopSuppliers ts ON cn.n_nationkey = ts.n_nationkey
    GROUP BY cn.n_name
)
SELECT fr.nation_name, fr.total_revenue, fr.total_supply_cost, fr.profitability
FROM FinalReport fr
WHERE fr.total_revenue IS NOT NULL
ORDER BY fr.nation_name;
