
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        cus.c_custkey,
        cus.c_name,
        cus.total_spent,
        ROW_NUMBER() OVER (ORDER BY cus.total_spent DESC) AS rank
    FROM CustomerOrderSummary cus
)
SELECT 
    rs.nation,
    ts.c_name AS top_customer,
    ts.total_spent,
    rs.total_cost,
    rs.rank AS supplier_rank
FROM RankedSuppliers rs
JOIN TopCustomers ts ON ts.rank <= 3
ORDER BY rs.nation, ts.total_spent DESC;
