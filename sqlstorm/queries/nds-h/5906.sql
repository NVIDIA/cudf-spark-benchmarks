WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.total_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank = 1
),
TopCustomers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_revenue
    FROM 
        CustomerOrders co
    WHERE 
        co.total_revenue > 10000
)
SELECT 
    tc.c_name,
    tc.total_revenue,
    ts.s_name,
    ts.total_cost
FROM 
    TopCustomers tc
JOIN 
    TopSuppliers ts ON tc.c_custkey = ts.s_suppkey
ORDER BY 
    tc.total_revenue DESC, ts.total_cost DESC
LIMIT 10;
