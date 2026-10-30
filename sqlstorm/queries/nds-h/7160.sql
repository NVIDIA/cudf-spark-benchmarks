WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_in_nation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank_in_nation <= 3
),
OrderCounts AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
),
CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        oc.order_count
    FROM 
        customer c
    JOIN 
        OrderCounts oc ON c.c_custkey = oc.o_custkey
    WHERE 
        c.c_acctbal > 1000
)
SELECT 
    tp.s_name,
    cp.c_name,
    cp.order_count,
    tp.total_supply_cost
FROM 
    TopSuppliers tp
JOIN 
    CustomerPurchases cp ON cp.order_count > 5
ORDER BY 
    tp.total_supply_cost DESC, cp.order_count ASC;
