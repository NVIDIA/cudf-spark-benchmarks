
WITH Supplier_Avg_Cost AS (
    SELECT ps_partkey, AVG(ps_supplycost) AS avg_supplycost
    FROM partsupp
    GROUP BY ps_partkey
),
Top_Suppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
Order_Summary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
Customer_Orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
),
Nation_Region AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    COALESCE(SUM(os.total_revenue), 0) AS total_revenue,
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END), 0) AS total_returns,
    COALESCE(SUM(tc.total_cost), 0) AS total_supplier_cost,
    nr.r_name AS region_name
FROM 
    Customer_Orders cs
LEFT JOIN Order_Summary os ON cs.o_orderkey = os.o_orderkey
LEFT JOIN lineitem l ON cs.o_orderkey = l.l_orderkey
LEFT JOIN Top_Suppliers tc ON l.l_suppkey = tc.s_suppkey
LEFT JOIN Nation_Region nr ON cs.c_custkey = (
    SELECT c.c_custkey
    FROM customer c
    WHERE c.c_nationkey = (
        SELECT n.n_nationkey
        FROM nation n
        WHERE n.n_name = 'Germany'
    )
)
GROUP BY 
    cs.c_custkey, 
    cs.c_name, 
    nr.r_name
ORDER BY 
    total_revenue DESC;
