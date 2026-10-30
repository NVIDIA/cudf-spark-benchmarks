WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F' AND l.l_shipdate >= '1997-01-01'
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
AggregateData AS (
    SELECT 
        np.n_name AS nation_name,
        SUM(sp.ps_supplycost * sp.ps_availqty) AS total_cost,
        SUM(co.total_spent) AS total_revenue
    FROM SupplierParts sp
    JOIN supplier s ON sp.s_suppkey = s.s_suppkey
    JOIN nation np ON s.s_nationkey = np.n_nationkey
    JOIN CustomerOrders co ON co.total_spent >= 10000
    GROUP BY np.n_name
)
SELECT 
    nation_name,
    total_cost,
    total_revenue,
    (total_revenue - total_cost) AS profit,
    CASE 
        WHEN total_revenue > total_cost THEN 'Profitable'
        ELSE 'Not Profitable'
    END AS profitability_status
FROM AggregateData
ORDER BY profit DESC
LIMIT 10;