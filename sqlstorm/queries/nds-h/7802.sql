WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER(PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) as supply_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal
    FROM 
        RankedSuppliers s
    WHERE 
        s.supply_rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_totalprice
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
)
SELECT 
    co.c_name,
    SUM(co.o_totalprice) AS total_spent,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    COUNT(DISTINCT ts.s_suppkey) AS distinct_suppliers
FROM 
    CustomerOrders co
JOIN 
    TopSuppliers ts ON co.c_custkey = ts.s_suppkey
GROUP BY 
    co.c_name
ORDER BY 
    total_spent DESC
LIMIT 10;