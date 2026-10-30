WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_supplycost DESC) AS rank
    FROM 
        RankedSuppliers
    WHERE 
        part_count > 5
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
        SUM(o.o_totalprice) > 10000
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.total_supplycost,
    co.c_custkey,
    co.c_name,
    co.total_spent
FROM 
    TopSuppliers ts
JOIN 
    CustomerOrders co ON ts.part_count > 10
WHERE 
    ts.total_supplycost > 50000
ORDER BY 
    ts.rank, co.total_spent DESC
LIMIT 10;
