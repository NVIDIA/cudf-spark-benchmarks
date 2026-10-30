WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost, 
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_phone, s.s_acctbal, rs.TotalSupplyCost
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    WHERE 
        rs.Rank <= 10
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 100000
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice 
    FROM 
        HighValueCustomers c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
OrderLineItems AS (
    SELECT 
        o.c_custkey, 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS OrderValue
    FROM 
        CustomerOrders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.c_custkey, o.o_orderkey
)
SELECT 
    ts.s_name,
    SUM(oli.OrderValue) AS TotalOrderValue
FROM 
    TopSuppliers ts
JOIN 
    OrderLineItems oli ON ts.s_suppkey = oli.c_custkey
GROUP BY 
    ts.s_name
ORDER BY 
    TotalOrderValue DESC;
