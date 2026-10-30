WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost) AS total_supplycost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        rs.total_supplycost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank_within_nation <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000
),
OrdersWithDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        li.l_quantity,
        li.l_extendedprice,
        li.l_discount,
        li.l_tax,
        ts.s_suppkey,
        ts.s_name
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    JOIN 
        TopSuppliers ts ON li.l_suppkey = ts.s_suppkey
)
SELECT 
    cwd.c_custkey,
    cwd.c_name,
    COUNT(owd.o_orderkey) AS total_orders,
    SUM(owd.o_totalprice) AS grand_total,
    AVG(owd.l_discount) AS average_discount
FROM 
    CustomerOrders cwd
JOIN 
    OrdersWithDetails owd ON cwd.c_custkey = owd.o_orderkey
GROUP BY 
    cwd.c_custkey, cwd.c_name
ORDER BY 
    grand_total DESC
LIMIT 10;
