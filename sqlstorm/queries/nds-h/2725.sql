WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY o.o_orderkey, o.o_custkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COALESCE(os.total_revenue, 0) AS total_revenue,
        RANK() OVER (ORDER BY COALESCE(os.total_revenue, 0) DESC) AS rank
    FROM customer c
    LEFT JOIN OrderStats os ON c.c_custkey = os.o_custkey
)
SELECT 
    tc.c_name,
    tc.total_revenue,
    ts.s_name AS top_supplier,
    ts.s_acctbal
FROM TopCustomers tc
LEFT JOIN RankedSuppliers ts ON tc.rank = ts.rank
WHERE tc.rank <= 10
ORDER BY tc.total_revenue DESC;