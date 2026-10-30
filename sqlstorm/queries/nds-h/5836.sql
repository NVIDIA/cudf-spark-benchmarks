WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER(PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name, 
        n.n_name AS nation_name, 
        rs.s_suppkey, 
        rs.s_name, 
        rs.total_cost
    FROM RankedSuppliers rs
    JOIN nation n ON rs.s_suppkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE rs.supplier_rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
)
SELECT 
    tso.region_name, 
    tso.nation_name, 
    tso.s_name AS supplier_name, 
    co.c_name AS customer_name, 
    co.total_spent
FROM TopSuppliers tso
JOIN CustomerOrders co ON tso.total_cost > co.total_spent
ORDER BY tso.region_name, tso.nation_name, tso.total_cost DESC, co.total_spent DESC;
